//
//  PlaceList.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(PlaceList)
public class PlaceList: NSManagedObject, Codable, EquatableObjects {
    static let NAME_KEY = "name"
    
    // A hack, but I can't figure out a better way to communicate an error when decoding. Specifically not persisted because if this is non-nil after decoding, I need to delete (and not persist) the object.
    private var existingPlaceList: PlaceList?

    enum PlaceListErrors : Error {
        case moreThanOnePlaceListWithName(String)
        case noNamePresent
    }
    
    class func entityName() -> String {
        return "PlaceList"
    }
    
    class func newObject(withName name: String) throws -> PlaceList {
        if let _ = getPlaceList(withName: name) {
            throw PlaceListErrors.moreThanOnePlaceListWithName(name)
        }
        
        let placeList = CoreData.sessionNamed(CoreDataExtras.sessionName)
            .newObject(withEntityName: entityName()) as! PlaceList
        placeList.name = name
        return placeList
    }
        
    enum CodingKeys: String, CodingKey {
       case name
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let context = CoreData.sessionNamed(CoreDataExtras.sessionName).context
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName(), in: context) else { fatalError() }
        self.init(entity: entity, insertInto: context)
        try decode(using: decoder)
    }
    
    // If existingPlaceList is non-nil after this call, you need use the existingPlaceList, and remove the newly decoded PlaceList.
    func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let name = try container.decodeIfPresent(String.self, forKey: .name) else {
            throw PlaceListErrors.noNamePresent
        }
        
        if let existingPlaceList = Self.getPlaceList(withName: name) {
            // This is an error! Specifically not setting `name` in this case.
            self.existingPlaceList = existingPlaceList
        }
        else {
            self.name = name
        }
    }
    
    // Dealing with the error hack in the decode.
    static func cleanupDecode(lists: Set<PlaceList>, add:(PlaceList)->()) {
        var toRemove = [PlaceList]()
        for list in lists {
            if let existingPlaceList = list.existingPlaceList {
                toRemove.append(list)
                add(existingPlaceList)
            }
            else {
                add(list)
            }
        }
        
        while !toRemove.isEmpty {
            let list = toRemove.remove(at: 0)
            CoreData.sessionNamed(CoreDataExtras.sessionName).remove(list)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
    
    class func getPlaceList(withName name: String) -> PlaceList? {
        var result: PlaceList?
     
        do {
            let placeLists = try CoreData.sessionNamed(CoreDataExtras.sessionName)
                .fetchAllObjects(withEntityName: entityName()) as! [PlaceList]
            // Not using name! in this because during Decoding a PlaceList may not yet have a name.
            let filteredPlaceLists = placeLists.filter({$0.name == name})
            
            switch filteredPlaceLists.count {
            case 0:
                break
                
            case 1:
                result = filteredPlaceLists[0]
                
            default:
                throw PlaceListErrors.moreThanOnePlaceListWithName(name)
            }
        } catch (let error) {
            Log.error("Error when calling getPlaceList: \(error)")
        }
        
        return result
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }

    // See also https://stackoverflow.com/questions/5813309/get-modification-date-for-nsmanagedobject-in-core-data
    override public func willSave() {
        super.willSave()
        if !isDeleted && changedValues()["modificationDate"] == nil {
            modificationDate = Date()
        }
    }
    
    class func fetchRequestForAllObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
        fetchRequest = CoreData.sessionNamed(CoreDataExtras.sessionName).fetchRequest(withEntityName: self.entityName(), modifyingFetchRequestWith: nil)
        
        if fetchRequest != nil {
            let sortDescriptor = NSSortDescriptor(key: NAME_KEY, ascending: true)
            fetchRequest!.sortDescriptors = [sortDescriptor]
        }
        
        return fetchRequest
    }
    
    static func equal(_ lhs: PlaceList?, _ rhs: PlaceList?) -> Bool {
        return lhs?.name == rhs?.name
    }
}

extension PlaceList: Recommendations {
    var dates: [Date] {
        return [modificationDate].compactMap{$0}
    }
}
