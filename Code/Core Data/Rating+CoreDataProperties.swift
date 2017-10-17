//
//  Rating+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/16/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension Rating {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Rating> {
        return NSFetchRequest<Rating>(entityName: "Rating")
    }

    @NSManaged public var rating: Float
    @NSManaged public var recommendedBy: String?
    @NSManaged public var again: NSNumber?
    @NSManaged public var meThem: NSNumber?
    @NSManaged public var location: Location?
    @NSManaged public var comment: Comment?

}
