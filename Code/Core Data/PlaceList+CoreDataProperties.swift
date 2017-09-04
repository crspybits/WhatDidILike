//
//  PlaceList+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/4/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension PlaceList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaceList> {
        return NSFetchRequest<PlaceList>(entityName: "PlaceList")
    }

    @NSManaged public var name: String?
    @NSManaged public var places: NSSet?

}

// MARK: Generated accessors for places
extension PlaceList {

    @objc(addPlacesObject:)
    @NSManaged public func addToPlaces(_ value: Place)

    @objc(removePlacesObject:)
    @NSManaged public func removeFromPlaces(_ value: Place)

    @objc(addPlaces:)
    @NSManaged public func addToPlaces(_ values: NSSet)

    @objc(removePlaces:)
    @NSManaged public func removeFromPlaces(_ values: NSSet)

}
