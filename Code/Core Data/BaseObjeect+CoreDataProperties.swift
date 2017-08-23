//
//  BaseObjeect+CoreDataProperties.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData


extension BaseObjeect {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseObjeect> {
        return NSFetchRequest<BaseObjeect>(entityName: "BaseObjeect")
    }

    @NSManaged public var creationDate: NSDate?
    @NSManaged public var modificationDate: NSDate?
    @NSManaged public var userName: String?

}
