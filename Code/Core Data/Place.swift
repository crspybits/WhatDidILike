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
public class Place: BaseObject, Codable, EquatableObjects, UUIDCollisionAvoidance {    
    static let UUID_KEY = "uuid"
    static let lastExportField = "lastExport"

    override class func entityName() -> String {
        return "Place"
    }
    
    static func alreadyExists(uuid: Foundation.UUID) throws -> UUIDCollisionResult<Place> {
        if let place = try Self.fetchObject(withUUID: uuid.uuidString) {
            return .existsWithObject(place)
        }
        else {
            return .doesNotExist
        }
    }
    
    // After you create a Place, make sure you give it at least one Location-- this is required by the model.
    override class func newObject() throws -> Place {
        let uuid: String = try realUUID()
        let result = try super.newObject() as! Place
        result.uuid = uuid
        return result
    }
    
    class func fetchAllObjects() -> [Place]? {
        let places = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: entityName())
        return places as? [Place]
    }
    
    class func fetchObject(withUUID uuid: String) throws -> Place? {
        guard let fetchRequest = fetchRequestForObjects(withUUID: uuid) else {
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
    
    private class func fetchRequestForObjects(withUUID uuid: String) -> NSFetchRequest<NSFetchRequestResult>? {
        var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
        
        fetchRequest = CoreData.sessionNamed(CoreDataExtras.sessionName).fetchRequest(
            withEntityName: self.entityName(), modifyingFetchRequestWith: { request in
            let predicate = NSPredicate(format: "(%K == %@)", UUID_KEY, uuid)
            request.predicate = predicate
        })

        if fetchRequest != nil {
            let sortDescriptor = NSSortDescriptor(key: UUID_KEY, ascending: true)
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
        case uuid
        case generalDescription
        case name
        case category
       
        // Not coding `suggestion` as this is computed from other properties

        case items
        case lists
        case locations
    }
    
    // Doesn't look for UUID collisions with existing Place uuid's.
    override func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate) as NSDate?
        modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate) as NSDate?
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
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
    
    // Because in some use cases I need to be able to peek at the encoded Place data first before committing to actually decoding the place.
    struct PartialPlace: Decodable {
        let uuid: String?
        let creationDate: NSDate?
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
            creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate) as NSDate?
        }
    }
    
    static func partialDecode(data: Data) throws -> PartialPlace {
        let decoder = JSONDecoder()
        return try decoder.decode(PartialPlace.self, from: data)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let creationDate = creationDate as Date? {
            try container.encode(creationDate, forKey: .creationDate)
        }
        
        if let modificationDate = modificationDate as Date? {
            try container.encode(modificationDate, forKey: .modificationDate)
        }
        
        try container.encode(uuid, forKey: .uuid)
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
        return lhs?.uuid == rhs?.uuid &&
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
        // Not including `lastExport` here because that date isn't user date data for Recommendations.
        
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
