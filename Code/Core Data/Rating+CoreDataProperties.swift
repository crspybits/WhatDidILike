//
//  Rating+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/19/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension Rating {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Rating> {
        return NSFetchRequest<Rating>(entityName: "Rating")
    }

    @NSManaged public var again: NSNumber?
    @NSManaged public var meThem: NSNumber?
    @NSManaged public var rating: Float
    @NSManaged public var recommendedBy: String?
    @NSManaged public var modificationDate: Date?
    @NSManaged public var comment: Comment?
    @NSManaged public var location: Location?

}
