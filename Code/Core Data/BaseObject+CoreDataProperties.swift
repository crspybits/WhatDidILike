//
//  BaseObject+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData


extension BaseObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseObject> {
        return NSFetchRequest<BaseObject>(entityName: "BaseObject")
    }

    @NSManaged public var creationDate: NSDate?
    @NSManaged public var modificationDate: NSDate?
    @NSManaged public var userName: String?

}
