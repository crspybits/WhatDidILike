//
//  Comment.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Comment)
public class Comment: BaseObject, RatingManagedObject, ImagesManagedObject {
    override class func entityName() -> String {
        return "Comment"
    }
    
    override class func newObject() -> Comment {
        return super.newObject() as! Comment
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func remove() {
        for imageObj in images! {
            let image = imageObj as! Image
            image.remove()
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
}
