//
//  Item+CoreDataClass.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Item)
public class Item: BaseObjeect {
    class func entityName() -> String {
        return "Item"
    }
    
    class func newObject() -> Item {
        let item = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Item
        return item
    }
}
