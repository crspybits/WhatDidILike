//
//  Item.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Item)
public class Item: BaseObject {
    class func entityName() -> String {
        return "Item"
    }
    
    class func newObject() -> Item {
        let item = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Item
        return item
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func remove() {
        for commentObj in comments! {
            let comment = commentObj as! Comment
            comment.remove()
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
}
