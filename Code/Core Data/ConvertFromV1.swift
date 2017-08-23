//
//  ConvertFromV1.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import SMCoreLib

class ConvertFromV1 {
    static let RESTAURANTS = "Restaurants.dat"

    static let KEY_DATE  = "date"
    static let KEY_USER_NAME = "userName"

    // Name of place (NSString)
    static let PLACE_KEY_NAME = "restaurantName"

    // List or menu of items for the place, an NSArray
    static let PLACE_KEY_MENU = "restaurantMenu"

    // Boolean represented as NSNumber; true ==> I liked it; false ==> you liked it.
    // Don't put "PLACE_" prefix on this key because I use this at other levels
    // (i.e., with items and comments) too.
    static let KEY_IATE = "iAte"
    static let PLACE_KEY_LOCATION = "storeLocation"

    // Lat/long in the form of a CLLocation
    static let PLACE_KEY_COORDS = "placeCoords"

    static let KEY_CATEGORY = "storeCategoryName"

    // Date of last modification to place (or item within place
    // or comment within item).
    static let KEY_MODIFICATION_DATE = "modificationDate"

    // NSString general textual description of the place.
    static let PLACE_KEY_GENERAL_DESCRIPTION = "placeGeneralDescription"

    // An NSArray of list names
    static let PLACE_KEY_LISTS = "placeListNames"

    // An NSArray of JPEG image names
    static let PLACE_KEY_IMAGES = "images"

    // Used to keep a record of distances computed while sorting using
    // distances.
    static let PLACE_KEY_SORT_DIST = "placeSortDist"

    // An individual list name (NSString)
    static let KEY_LIST_NAME = "listName"

    static let ITEM_KEY_NAME = "menuItemName"
    static let KEY_RATING = "rating"
    static let ITEM_KEY_COMMENTS = "menuItemComments"
    static let COMMENT_KEY_IMAGE_FILENAME = "imageFileName"
    static let COMMENT_KEY_COMMENT = "menuItemComment"
    
    static func doIt() {
        let placeFilePath = FileStorage.path(toItem: RESTAURANTS)
        
        // Temporary
        //NSString *placeFilePath = [[NSBundle mainBundle] pathForResource:@"Restaurants" ofType:@"dat"];
        
        let places = FileStorage.loadApplicationData(fromFlatFile: placeFilePath) as! [[String:Any]]
        
        var numberPlaces = 0
        var totalNumberItems = 0
        var totalNumberComments = 0
        var numberImages = 0
        var numberImageErrors = 0
    
        // Move a large image in the Documents directory to the LARGE_IMAGE_DIRECTORY. Also renames the image to make the name format more standard. Returns the renamed image file name (without path) or nil on an error.
        func moveLargeImage(largeImageFileName: String) -> String? {
            let imageFilePath = FileStorage.path(toItem: largeImageFileName)

            // Image file names are currently in the format: WhatDidILike.jpg.XXXXX right now. To make them easier to deal with as images, change them to WhatDidILike.XXXXX.jpg
            let uniqueXXXXPart =  (largeImageFileName as NSString).pathExtension
            let newFileName = "\(Identifiers.APP_NAME).\(uniqueXXXXPart).jpg"

            let imageNewFilePath = FileStorage.path(toItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY) + "/" + newFileName
            
            do {
                try FileManager.default.moveItem(atPath: imageFilePath!, toPath: imageNewFilePath)
            } catch (let error) {
                Log.error("Error \(error)")
                numberImageErrors += 1
                return nil
            }

            numberImages += 1
            return newFileName
        }
 
        for restaurant in places {
            let coreDataPlace = Place.newObject()
            coreDataPlace.creationDate = (restaurant[KEY_DATE] as! NSDate)
            coreDataPlace.modificationDate = (restaurant[KEY_MODIFICATION_DATE] as! NSDate)
            coreDataPlace.generalDescription = (restaurant[PLACE_KEY_GENERAL_DESCRIPTION] as! String)
            coreDataPlace.name = (restaurant[PLACE_KEY_NAME] as! String)
            coreDataPlace.category = (restaurant[KEY_CATEGORY] as! String)
            coreDataPlace.userName = (restaurant[KEY_USER_NAME] as! String)
            
            if let listNames = restaurant[PLACE_KEY_LISTS] as? [String], listNames.count > 0 {
                coreDataPlace.csvListNames = NSString.convert(toCSV: listNames)
            }
            
            let coreDataLocation = Location.newObject()
            coreDataPlace.addToLocations(coreDataLocation)
            
            coreDataLocation.meThem = (restaurant[KEY_IATE] as! Bool)
            coreDataLocation.address = (restaurant[PLACE_KEY_LOCATION] as! String)
            coreDataLocation.rating = (restaurant[KEY_RATING] as! Float)
            
            // Since the location info was all previously part of the place info, it makes sense to also use the creation date and modification date here.
            coreDataLocation.creationDate = coreDataPlace.creationDate
            coreDataLocation.modificationDate = coreDataPlace.modificationDate
            
            if let imageNames = restaurant[PLACE_KEY_IMAGES] as? [String] {
                var newImageNames = [String]()
                for imageName in imageNames {
                    if let newImageName = moveLargeImage(largeImageFileName: imageName) {
                        newImageNames.append(newImageName)
                    }
                }
                
                coreDataLocation.csvImageNames = NSString.convert(toCSV: newImageNames)
            }
        }
    }
}
