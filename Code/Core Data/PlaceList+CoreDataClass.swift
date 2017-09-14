//
//  PlaceList+CoreDataClass.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(PlaceList)
public class PlaceList: NSManagedObject {
    enum PlaceListErrors : Error {
        case moreThanOnePlaceListWithName(String)
    }
    
    class func entityName() -> String {
        return "PlaceList"
    }
    
    class func newObject(withName name: String) throws -> PlaceList {
        if let _ = getPlaceList(withName: name) {
            throw PlaceListErrors.moreThanOnePlaceListWithName(name)
        }
        
        let placeList = CoreData.sessionNamed(CoreDataExtras.sessionName)
            .newObject(withEntityName: entityName()) as! PlaceList
        placeList.name = name
        return placeList
    }
    
    class func getPlaceList(withName name: String) -> PlaceList? {
        var result: PlaceList?
     
        do {
            let placeLists = try CoreData.sessionNamed(CoreDataExtras.sessionName)
                .fetchAllObjects(withEntityName: entityName()) as! [PlaceList]
            let filteredPlaceLists = placeLists.filter({$0.name! == name})
            
            switch filteredPlaceLists.count {
            case 0:
                break
                
            case 1:
                result = filteredPlaceLists[0]
                
            default:
                throw PlaceListErrors.moreThanOnePlaceListWithName(name)
            }
        } catch (let error) {
            Log.error("Error when calling getPlaceList: \(error)")
        }
        
        return result
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}
