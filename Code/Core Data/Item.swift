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
    override class func entityName() -> String {
        return "Item"
    }
    
    override class func newObject() -> Item {
        return super.newObject() as! Item
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

extension Item {
    override var dates: [Date] {
        var result = [Date]()
        
        if let comments = comments {
            for comment in comments {
                if let comment = comment as? Comment {
                    result += comment.dates
                }
            }
        }
        
        return super.dates + result
    }
}
