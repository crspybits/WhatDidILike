//
//  Place.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Place)
public class Place: BaseObject {
    override class func entityName() -> String {
        return "Place"
    }
    
    // After you create a Place, make sure you give it at least one Location-- this is required by the model.
    override class func newObject() -> Place {
        return super.newObject() as! Place
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    // Assumes deletion of any needed location has already occurred.
    func remove() {
        for itemObj in items! {
            let item = itemObj as! Item
            item.remove()
        }
        
        // Not going remove a category even if there are no places referencing it any more. The user can manually delete it if they want to.
        // Similarly, for lists.
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
}
