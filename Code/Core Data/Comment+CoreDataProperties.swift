//
//  Comment+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData


extension Comment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Comment> {
        return NSFetchRequest<Comment>(entityName: "Comment")
    }

    @NSManaged public var comment: String?
    @NSManaged public var csvImageNames: String?
    @NSManaged public var meThem: Bool
    @NSManaged public var rating: Float
    @NSManaged public var item: Item?

}
