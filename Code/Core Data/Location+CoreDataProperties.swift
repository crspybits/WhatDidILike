//
//  Location+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/12/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var address: String?
    @NSManaged public var internalDistance: Float
    @NSManaged public var internalGoBack: NSNumber?
    @NSManaged public var internalLocation: Data?
    @NSManaged public var internalRating: Float
    @NSManaged public var specificDescription: String?
    @NSManaged public var images: NSOrderedSet?
    @NSManaged public var place: Place?
    @NSManaged public var rating: Rating?
    @NSManaged public var checkin: NSSet?

}

// MARK: Generated accessors for images
extension Location {

    @objc(insertObject:inImagesAtIndex:)
    @NSManaged public func insertIntoImages(_ value: Image, at idx: Int)

    @objc(removeObjectFromImagesAtIndex:)
    @NSManaged public func removeFromImages(at idx: Int)

    @objc(insertImages:atIndexes:)
    @NSManaged public func insertIntoImages(_ values: [Image], at indexes: NSIndexSet)

    @objc(removeImagesAtIndexes:)
    @NSManaged public func removeFromImages(at indexes: NSIndexSet)

    @objc(replaceObjectInImagesAtIndex:withObject:)
    @NSManaged public func replaceImages(at idx: Int, with value: Image)

    @objc(replaceImagesAtIndexes:withImages:)
    @NSManaged public func replaceImages(at indexes: NSIndexSet, with values: [Image])

    @objc(addImagesObject:)
    @NSManaged public func addToImages(_ value: Image)

    @objc(removeImagesObject:)
    @NSManaged public func removeFromImages(_ value: Image)

    @objc(addImages:)
    @NSManaged public func addToImages(_ values: NSOrderedSet)

    @objc(removeImages:)
    @NSManaged public func removeFromImages(_ values: NSOrderedSet)

}

// MARK: Generated accessors for checkin
extension Location {

    @objc(addCheckinObject:)
    @NSManaged public func addToCheckin(_ value: Checkin)

    @objc(removeCheckinObject:)
    @NSManaged public func removeFromCheckin(_ value: Checkin)

    @objc(addCheckin:)
    @NSManaged public func addToCheckin(_ values: NSSet)

    @objc(removeCheckin:)
    @NSManaged public func removeFromCheckin(_ values: NSSet)

}
