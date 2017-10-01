//
//  Location.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Location)
public class Location: BaseObject {
    static let NAME_KEY = "place.name"
    
    // Doesn't save the core data object when you set.
    // Don't access internalLocation directly. Use this method instead.
    var location:CLLocation? {
        set {
            if newValue == nil {
                internalLocation = nil
            }
            else {
                internalLocation = NSKeyedArchiver.archivedData(withRootObject: newValue!) as NSData
            }
        }
        get {
            if internalLocation == nil {
                return nil
            }
            else {
                return (NSKeyedUnarchiver.unarchiveObject(with: internalLocation! as Data) as! CLLocation)
            }
        }
    }
    
    class func entityName() -> String {
        return "Location"
    }
    
    class func newObject() -> Location {
        let location = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Location
        return location
    }
    
    class func fetchRequestForAllObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
        fetchRequest = CoreData.sessionNamed(CoreDataExtras.sessionName).fetchRequest(withEntityName: self.entityName(), modifyingFetchRequestWith: nil)
        
        if fetchRequest != nil {
            let sortDescriptor = NSSortDescriptor(key: NAME_KEY, ascending: true)
            fetchRequest!.sortDescriptors = [sortDescriptor]
        }
        
        return fetchRequest
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}
