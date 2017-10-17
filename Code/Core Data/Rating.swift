//
//  Rating.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/16/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(Rating)
public class Rating: NSManagedObject {
    class func entityName() -> String {
        return "Rating"
    }
    
    class func newObject() -> Rating {
        let rating = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Rating
        
        // These range from 0 to 1. Starting it off mid-way.
        rating.rating = 0.5
        
        return rating
    }
    
    func remove() {        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}
