//
//  Location+CoreDataClass.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Location)
public class Location: BaseObjeect {
    class func entityName() -> String {
        return "Location"
    }
    
    class func newObject() -> Location {
        let location = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Location
        return location
    }
}
