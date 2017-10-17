//
//  BaseObject.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/30/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(BaseObject)
public class BaseObject: NSManagedObject {
    // Superclass *must* override
    class func entityName() -> String {
        assert(false)
        return ""
    }
    
    class func newObject() -> NSManagedObject {
        let newObj = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! BaseObject
        newObj.creationDate = NSDate()
        newObj.userName = Parameters.userName.stringValue
        return newObj
    }
    
    // See also https://stackoverflow.com/questions/5813309/get-modification-date-for-nsmanagedobject-in-core-data
    override public func willSave() {
        super.willSave()
        if !isDeleted && changedValues()["modificationDate"] == nil {
            modificationDate = NSDate()
        }
    }
}
