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
public class Location: BaseObject, ImagesManagedObject {
    static let NAME_KEY = "place.name"
    static let DISTANCE_KEY = "internalDistance"

    // I'm not using `internalDistance` directly just to emphasize that this is a little different. It's for the UI so we can order locations by distance.
    var sortingDistance:Float {
        set {
            internalDistance = newValue
        }
        
        get {
            return internalDistance
        }
    }
    
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
    
    override class func entityName() -> String {
        return "Location"
    }
    
    override class func newObject() -> Location {
        let newLocation = super.newObject() as! Location
        newLocation.rating = Rating.newObject()
        return newLocation
    }
    
    class func fetchRequestForAllObjects(sortingOrder: OrderFilter.OrderFilterType) -> NSFetchRequest<NSFetchRequestResult>? {
        var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
        fetchRequest = CoreData.sessionNamed(CoreDataExtras.sessionName).fetchRequest(withEntityName: self.entityName(), modifyingFetchRequestWith: nil)
        
        var key: String
        var ascending: Bool
        
        switch sortingOrder {
        case .distance(ascending: let ascend):
            key = DISTANCE_KEY
            ascending = ascend
            
        case .name(ascending: let ascend):
            key = NAME_KEY
            ascending = ascend
        }
        
        if fetchRequest != nil {
            let sortDescriptor = NSSortDescriptor(key: key, ascending: ascending)
            fetchRequest!.sortDescriptors = [sortDescriptor]
        }
        
        return fetchRequest
    }
    
    class func fetchAllObjects() -> [Location]? {
        let locations = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: entityName())
        return locations as? [Location]
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func remove() {
        // Does the place associated with this location have more than one location?
        if place!.locations!.count == 1 {
            // No: the associated place needs to be removed too.
            place!.remove()
        }
        
        for imageObj in images! {
            let image = imageObj as! Image
            image.remove()
        }
        
        rating!.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
    
    static func metersToMiles(meters:Float) -> Float {
        return (meters/1000.0)*0.621371
    }
}
