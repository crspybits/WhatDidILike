//
//  Checkin+CoreDataClass.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/12/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(Checkin)
public class Checkin: NSManagedObject {
    class func entityName() -> String {
        return "Checkin"
    }
    
    class func newObject() -> Checkin {
        let checkin = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Checkin
        checkin.date = Date()
        return checkin
    }
}

extension Checkin: Recommendations {
    var dates: [Date] {
        // Forced unwrap is OK because I assign a Date when each object is created.
        return [date!]
    }
}
