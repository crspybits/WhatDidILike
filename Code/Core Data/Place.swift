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
    override class func entityName() -> String {
        return "Place"
    }
    
    // After you create a Place, make sure you give it at least one Location-- this is required by the model.
    override class func newObject() -> Place {
        return super.newObject() as! Place
    }
    
    class func fetchAllObjects() -> [Place]? {
        let places = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: entityName())
        return places as? [Place]
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
        return lhs?.generalDescription == rhs?.generalDescription &&
            lhs?.name == rhs?.name &&
            PlaceCategory.equal(lhs?.category, rhs?.category) &&
            Item.equal(lhs?.items?.array as? [Item], rhs?.items?.array as? [Item]) &&
            PlaceList.equal(lhs?.lists as? Set<PlaceList>, rhs?.lists as? Set<PlaceList>) &&
            Location.equal(lhs?.locations as? Set<Location>, rhs?.locations as? Set<Location>)
    }
}

extension Place {
    override var dates: [Date] {
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
