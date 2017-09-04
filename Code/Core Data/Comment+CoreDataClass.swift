//
//  Comment+CoreDataClass.swift
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
}
