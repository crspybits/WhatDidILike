//
//  Place.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Place)
public class Place: BaseObject, Codable, EquatableObjects {
    typealias IdType = Int32
    static let ID_KEY = "id"
    static let lastExportField = "lastExport"
    
    private static let _nextId = SMPersistItemInt(name: "Place.nextId", initialIntValue: 0, persistType: .userDefaults)
    static var nextId: IdType {
        let result = _nextId.intValue
        _nextId.intValue += 1
        return IdType(result)
    }

    override class func entityName() -> String {
        return "Place"
    }
    
    // After you create a Place, make sure you give it at least one Location-- this is required by the model.
    override class func newObject() -> Place {
        let result = super.newObject() as! Place
        result.id = nextId as NSNumber
        return result
    }
    
    class func fetchAllObjects() -> [Place]? {
        let places = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: entityName())
        return places as? [Place]
    }
    
    class func fetchObject(withId id: IdType) throws -> Place? {
        guard let fetchRequest = fetchRequestForObjects(withId: id) else {
            return nil
        }
                
        let moc = CoreData.sessionNamed(CoreDataExtras.sessionName).context
        guard let results = try moc.fetch(fetchRequest) as? [Place] else {
            return nil
        }
        
        if results.count == 0 {
            return nil
        }
        
        return results[0]
    }
    
    private class func fetchRequestForObjects(withId id: IdType) -> NSFetchRequest<NSFetchRequestResult>? {
        var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
        fetchRequest = CoreData.sessionNamed(CoreDataExtras.sessionName).fetchRequest(
            withEntityName: self.entityName(), modifyingFetchRequestWith: { request in
            let id = NSNumber(integerLiteral: Int(id))
            let predicate = NSPredicate(format: "(%K == %@)", ID_KEY, id)
            request.predicate = predicate
        })

        if fetchRequest != nil {
            let sortDescriptor = NSSortDescriptor(key: ID_KEY, ascending: true)
            fetchRequest!.sortDescriptors = [sortDescriptor]
        }
        
        return fetchRequest
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    // Assumes deletion of any needed location has already occurred.
    func remove() {
        for itemObj in items! {
            let item = itemObj as! Item
            item.remove()
        }
        
        // Not going remove a category even if there are no places referencing it any more. The user can manually delete it if they want to.
        // Similarly, for lists.
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case creationDate
        case modificationDate
        case id
        case generalDescription
        case name
        case category
       
        // Not coding `suggestion` as this is computed from other properties

        case items
        case lists
        case locations
    }
        
    override func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate) as NSDate?
        modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate) as NSDate?
        id = try container.decodeIfPresent(IdType.self, forKey: .id) as NSNumber?
        generalDescription = try container.decodeIfPresent(String.self, forKey: .generalDescription)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        if let category = try container.decodeIfPresent(PlaceCategory.self, forKey: .category) {
            PlaceCategory.cleanupDecode(category: category, add: { category in
                category.addToPlaces(self)
            })
        }

        if let items = try container.decodeIfPresent([Item].self, forKey: .items) {
            addToItems(NSOrderedSet(array: items))
        }
        
        if let lists = try container.decodeIfPresent(Set<PlaceList>.self, forKey: .lists) {
            PlaceList.cleanupDecode(lists: lists, add: { list in
                self.addToLists(list)
            })
        }
        
        if let locations = try container.decodeIfPresent(Set<Location>.self, forKey: .locations) {
            addToLocations(locations as NSSet)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let creationDate = creationDate as Date? {
            try container.encode(creationDate, forKey: .creationDate)
        }
        
        if let modificationDate = modificationDate as Date? {
            try container.encode(modificationDate, forKey: .modificationDate)
        }
        
        try container.encode(id?.int32Value, forKey: .id)
        try container.encode(generalDescription, forKey: .generalDescription)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)

        if let items = items?.array as? [Item] {
            try container.encode(items, forKey: .items)
        }
        
        if let lists = lists as? Set<PlaceList> {
            try container.encode(lists, forKey: .lists)
        }
        
        if let locations = locations as? Set<Location> {
            try container.encode(locations, forKey: .locations)
        }
    }
    
    static func equal(_ lhs: Place?, _ rhs: Place?) -> Bool {
        return lhs?.id == rhs?.id &&
            lhs?.generalDescription == rhs?.generalDescription &&
            lhs?.name == rhs?.name &&
            PlaceCategory.equal(lhs?.category, rhs?.category) &&
            Item.equal(lhs?.items?.array as? [Item], rhs?.items?.array as? [Item]) &&
            PlaceList.equal(lhs?.lists as? Set<PlaceList>, rhs?.lists as? Set<PlaceList>) &&
            Location.equal(lhs?.locations as? Set<Location>, rhs?.locations as? Set<Location>)
    }
}

extension Place {
    // Recommendation dates.
    override var dates: [Date] {
        // Not including `lastExport` here because that date doesn't user date data for Recommendations.
        
        var result = [Date]()
        
        if let locations = locations as? Set<Location> {
            for location in locations {
                result += location.dates
            }
        }
        
        if let items = items {
            for item in items {
                if let item = item as? Item {
                    result += item.dates
                }
            }
        }
        
        return super.dates + result
    }
    
    // I'm providing this because the `dates` property was originally intended for recommendations for places. The date updates provided by PlaceList and PlaceCategory don't really fit this because they are more or less independent of Place's. e.g., if I change a PlaceCategory name that impacts multiple Place's.
    var lastExportModificationDate: Date {
        var result = dates
        
        if let lists = lists as? Set<PlaceList> {
            for list in lists {
                result += [list.modificationDate].compactMap{$0}
            }
        }
        
        if let category = category {
            result += [category.modificationDate].compactMap{$0}
        }
        
        return result.max()!
    }
    
    // Doesn't save
    func setSuggestion() {
        let distinctDates = numberOfDistinctDates(dates)
        suggestion = Float(distinctDates)
    }
}

extension Place: ImportExport {
    var largeImageFiles: [String] {
        var result = [String]()
        
        if let items = self.items?.array as? [Item] {
            result += items.map{$0.largeImageFiles}.flatMap{$0}
        }
        
        if let locations = self.locations as? Set<Location> {
            result += locations.map{$0.largeImageFiles}.flatMap{$0}
        }
        
        return result
    }
}
