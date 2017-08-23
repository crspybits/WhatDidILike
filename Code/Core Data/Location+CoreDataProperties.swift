//
//  Location+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var address: String?
    @NSManaged public var csvImageNames: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var meThem: Bool
    @NSManaged public var name: String?
    @NSManaged public var rating: Float
    @NSManaged public var specificDescription: String?
    @NSManaged public var place: Place?

}
