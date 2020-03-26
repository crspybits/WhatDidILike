//
//  Place+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/23/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension Place {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Place> {
        return NSFetchRequest<Place>(entityName: "Place")
    }

    @NSManaged public var generalDescription: String?
    @NSManaged public var uuid: String?
    @NSManaged public var lastExport: Date?
    @NSManaged public var name: String?
    @NSManaged public var suggestion: Float
    @NSManaged public var category: PlaceCategory?
    @NSManaged public var items: NSOrderedSet?
    @NSManaged public var lists: NSSet?
    @NSManaged public var locations: NSSet?

}

// MARK: Generated accessors for items
extension Place {

    @objc(insertObject:inItemsAtIndex:)
    @NSManaged public func insertIntoItems(_ value: Item, at idx: Int)

    @objc(removeObjectFromItemsAtIndex:)
    @NSManaged public func removeFromItems(at idx: Int)

    @objc(insertItems:atIndexes:)
    @NSManaged public func insertIntoItems(_ values: [Item], at indexes: NSIndexSet)

    @objc(removeItemsAtIndexes:)
    @NSManaged public func removeFromItems(at indexes: NSIndexSet)

    @objc(replaceObjectInItemsAtIndex:withObject:)
    @NSManaged public func replaceItems(at idx: Int, with value: Item)

    @objc(replaceItemsAtIndexes:withItems:)
    @NSManaged public func replaceItems(at indexes: NSIndexSet, with values: [Item])

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: Item)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: Item)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSOrderedSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSOrderedSet)

}

// MARK: Generated accessors for lists
extension Place {

    @objc(addListsObject:)
    @NSManaged public func addToLists(_ value: PlaceList)

    @objc(removeListsObject:)
    @NSManaged public func removeFromLists(_ value: PlaceList)

    @objc(addLists:)
    @NSManaged public func addToLists(_ values: NSSet)

    @objc(removeLists:)
    @NSManaged public func removeFromLists(_ values: NSSet)

}

// MARK: Generated accessors for locations
extension Place {

    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: Location)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: Location)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSSet)

}
