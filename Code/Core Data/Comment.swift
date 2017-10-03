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
public class Comment: BaseObject {
    class func entityName() -> String {
        return "Comment"
    }
    
    class func newObject() -> Comment {
        let comment = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Comment
        return comment
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
