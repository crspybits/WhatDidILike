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
    static let NAME_KEY = "name"
    
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
    
    // Looks up the category in a case insensitive manner.
    class func getCategory(withName name: String) -> PlaceCategory? {
        var result: PlaceCategory?
        
        do {
            let categories = try CoreData.sessionNamed(CoreDataExtras.sessionName)
                .fetchAllObjects(withEntityName: entityName()) as! [PlaceCategory]
            
            let filteredCategories = categories.filter({
                return $0.name!.caseInsensitiveCompare(name) == ComparisonResult.orderedSame
            })
            
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
