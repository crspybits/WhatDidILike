//
//  PlaceCategory+CoreDataClass.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(PlaceCategory)
public class PlaceCategory: NSManagedObject {
    enum PlaceCategoryErrors : Error {
        case moreThanOneCategoryWithName(String)
    }
    
    class func entityName() -> String {
        return "PlaceCategory"
    }
    
    class func newObject(withName name: String) throws -> PlaceCategory {
        if let _ = getCategory(withName: name) {
            throw PlaceCategoryErrors.moreThanOneCategoryWithName(name)
        }
        
        let placeCategory = CoreData.sessionNamed(CoreDataExtras.sessionName)
            .newObject(withEntityName: entityName()) as! PlaceCategory
        placeCategory.name = name
        return placeCategory
    }
    
    class func getCategory(withName name: String) -> PlaceCategory? {
        var result: PlaceCategory?
        
        do {
            let categories = try CoreData.sessionNamed(CoreDataExtras.sessionName)
                .fetchAllObjects(withEntityName: entityName()) as! [PlaceCategory]
            let filteredCategories = categories.filter({$0.name! == name})
            
            switch filteredCategories.count {
            case 0:
                break
                
            case 1:
                result = filteredCategories[0]
                
            default:
                throw PlaceCategoryErrors.moreThanOneCategoryWithName(name)
            }
        } catch (let error) {
            Log.error("Error when calling getCategory: \(error)")
        }
        
        return result
    }
}
