//
//  PlaceCategory.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(PlaceCategory)
public class PlaceCategory: NSManagedObject, Codable, EquatableObjects {
    static let NAME_KEY = "name"
    
    // A hack, but I can't figure out a better way to communicate an error when decoding. Specifically not persisted because if this is non-nil after decoding, I need to delete (and not persist) the object.
    private var existingCategory: PlaceCategory?
    
    enum PlaceCategoryErrors : Error {
        case moreThanOneCategoryWithName(String)
        case noNamePresent
    }
    
    class func entityName() -> String {
        return "PlaceCategory"
    }
    
    class func newObject(withName name: String) throws -> PlaceCategory {
        if let _ = getCategory(withName: name) {
            throw PlaceCategoryErrors.moreThanOneCategoryWithName(name)
        }
        
        let placeCategory = CoreData.sessionNamed(CoreDataExtras.sessionName)
            .newObject(withEntityName: entityName()) as! PlaceCategory
        placeCategory.name = name
        return placeCategory
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
    
    // If existingCategory is non-nil after this call, you need use the existingCategory, and remove the newly decoded PlaceCategory. The decoded PlaceCategory has no name if existingCategory is non-nil.
    func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let name = try container.decodeIfPresent(String.self, forKey: .name) else {
            throw PlaceCategoryErrors.noNamePresent
        }
        
        if let existingCategory = Self.getCategory(withName: name) {
            // This is an error! Specifically not setting `name` in this case.
            self.existingCategory = existingCategory
        }
        else {
            self.name = name
        }
    }
    
    // Dealing with the error hack in the decode.
    static func cleanupDecode(category: PlaceCategory, add:(PlaceCategory)->()) {
        if let existingCategory = category.existingCategory {
            CoreData.sessionNamed(CoreDataExtras.sessionName).remove(category)
            add(existingCategory)
        }
        else {
            add(category)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
    

    
    // Looks up the category in a case insensitive manner. Returns nil if no category with name.
    class func getCategory(withName name: String) -> PlaceCategory? {
        var result: PlaceCategory?
        
        do {
            let categories = try CoreData.sessionNamed(CoreDataExtras.sessionName)
                .fetchAllObjects(withEntityName: entityName()) as! [PlaceCategory]
            
            let filteredCategories = categories.filter({
                // Using `?` in this because during Decoding a PlaceCategory may not yet have a name.
                return $0.name?.caseInsensitiveCompare(name) == ComparisonResult.orderedSame
            })
            
            switch filteredCategories.count {
            case 0:
                break
                
            case 1:
                result = filteredCategories[0]
                
            default:
                throw PlaceCategoryErrors.moreThanOneCategoryWithName(name)
            }
        } catch (let error) {
            Log.error("Error when calling getCategory: \(error)")
        }
        
        return result
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
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    static func equal(_ lhs: PlaceCategory?, _ rhs: PlaceCategory?) -> Bool {
        return lhs?.name == rhs?.name
    }
}
