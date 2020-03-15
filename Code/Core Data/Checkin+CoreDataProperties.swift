//
//  Checkin+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/12/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension Checkin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Checkin> {
        return NSFetchRequest<Checkin>(entityName: "Checkin")
    }

    @NSManaged public var date: Date?
    @NSManaged public var location: Location?

}
