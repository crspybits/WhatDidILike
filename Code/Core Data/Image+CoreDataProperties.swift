//
//  Image+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/2/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension Image {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged public var fileName: String?
    @NSManaged public var comment: Comment?
    @NSManaged public var location: Location?

}
