//
//  ConvertFromV1.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import SMCoreLib
import M13ProgressSuite

class ConvertFromV1 {
    let RESTAURANTS = "Restaurants.dat"

    let KEY_DATE  = "date"
    let KEY_USER_NAME = "userName"

    // Name of place (NSString)
    let PLACE_KEY_NAME = "restaurantName"

    // List or menu of items for the place, an NSArray
    let PLACE_KEY_MENU = "restaurantMenu"

    // Boolean represented as NSNumber; true ==> I liked it; false ==> you liked it.
    // Don't put "PLACE_" prefix on this key because I use this at other levels
    // (i.e., with items and comments) too.
    let KEY_IATE = "iAte"
    let PLACE_KEY_LOCATION = "storeLocation"

    // Lat/long in the form of a CLLocation
    let PLACE_KEY_COORDS = "placeCoords"

    let KEY_CATEGORY = "storeCategoryName"

    // Date of last modification to place (or item within place
    // or comment within item).
    let KEY_MODIFICATION_DATE = "modificationDate"

    // NSString general textual description of the place.
    let PLACE_KEY_GENERAL_DESCRIPTION = "placeGeneralDescription"

    // An NSArray of list names
    let PLACE_KEY_LISTS = "placeListNames"

    // An NSArray of JPEG image names
    let PLACE_KEY_IMAGES = "images"

    // Used to keep a record of distances computed while sorting using
    // distances.
    let PLACE_KEY_SORT_DIST = "placeSortDist"

    // An individual list name (NSString)
    let KEY_LIST_NAME = "listName"

    let ITEM_KEY_NAME = "menuItemName"
    let KEY_RATING = "rating"
    let ITEM_KEY_COMMENTS = "menuItemComments"
    let COMMENT_KEY_IMAGE_FILENAME = "imageFileName"
    let COMMENT_KEY_COMMENT = "menuItemComment"
    
    var numberPlaces = 0
    var numberImages = 0
    var numberImageErrors = 0
    var imageErrorDescriptions = [String]()
    var numberItems = 0
    var numberComments = 0
    var numberCategoriesCreated = 0
    var numberCategoryCreationErrors = 0
    var numberListNamesCreated = 0
    var numberListNameCreationErrors = 0
    var errorRemovingIconsDirectory:Bool = false
    var commentStyle: Parameters.CommentStyle!
    var places:[[String:Any]]!
    var hud:M13ProgressHUD!
    
    init?(viewController:UIViewController) {
        // Temporary
        //let placeFilePath = Bundle.main.path(forResource: "Restaurants", ofType: "dat")
        
        let placeFilePath = FileStorage.path(toItem: RESTAURANTS)
        Log.msg("\(String(describing: placeFilePath))")
        
        guard let places = FileStorage.loadApplicationData(fromFlatFile: placeFilePath) as? [[String:Any]] else {
            return nil
        }

        self.places = places
    }
    
    private func showHud() {
        let ring = M13ProgressViewRing()
        ring.showPercentage = false
        ring.progressRingWidth = 10
        if let hud = M13ProgressHUD(progressView: ring),
            let window = UIApplication.shared.delegate?.window,
            let w = window {
            hud.progressViewSize = CGSize(width:60.0, height:60.0)
            hud.animationPoint = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height / 2)
            w.addSubview(hud)
            hud.show(true)
            self.hud = hud
            w.layoutIfNeeded()
        }
    }
    
    // Move a large image in the Documents directory to the LARGE_IMAGE_DIRECTORY. Also renames the image to make the name format more standard. Returns the renamed image file name (without path) or nil on an error.
    private func moveLargeImage(largeImageFileName: String) -> String? {
        let imageFilePath = FileStorage.path(toItem: largeImageFileName)

        // Image file names are currently in the format: WhatDidILike.jpg.XXXXX right now. To make them easier to deal with as images, change them to WhatDidILike.XXXXX.jpg
        let uniqueXXXXPart =  (largeImageFileName as NSString).pathExtension
        let newFileName = "\(Identifiers.APP_NAME).\(uniqueXXXXPart).jpg"

        let largeImagesDirURL = FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY)
        FileStorage.createDirectoryIfNeeded(largeImagesDirURL)
        
        let imageNewFilePath = FileStorage.path(toItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY) + "/" + newFileName
        
        do {
            try FileManager.default.moveItem(atPath: imageFilePath!, toPath: imageNewFilePath)
        } catch (let error) {
            Log.error("Error moving image \(error)")
            numberImageErrors += 1
            return nil
        }

        numberImages += 1
        return newFileName
    }
    
    func doIt(commentStyle: Parameters.CommentStyle) {
        self.commentStyle = commentStyle
        
        // Get rid of "icons" directory-- we can use our current technique for generating these files on the fly-- with naming for their sizes.
        let iconsDirURL = FileStorage.url(ofItem: "icons")!
        do {
            try FileManager.default.removeItem(at: iconsDirURL)
        } catch {
            errorRemovingIconsDirectory = true
        }
        
        numberPlaces = places.count
        var currentPlaceIndex = 0

        showHud()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            doNextRestaurant()
        }
        
        func doNextRestaurant() {
            let restaurant = places[currentPlaceIndex]
            
            if let coreDataPlace = try? Place.newObject() {
                coreDataPlace.creationDate = restaurant[KEY_DATE] as? NSDate
                coreDataPlace.modificationDate = restaurant[KEY_MODIFICATION_DATE] as? NSDate
                coreDataPlace.generalDescription = restaurant[PLACE_KEY_GENERAL_DESCRIPTION] as? String
                coreDataPlace.name = restaurant[PLACE_KEY_NAME] as? String
                
                if let categoryName = restaurant[KEY_CATEGORY] as? String {
                    var placeCategory:PlaceCategory?
                    if let existingCategory = PlaceCategory.getCategory(withName: categoryName) {
                        placeCategory = existingCategory
                    }
                    else {
                        if let newPlaceCategory = try? PlaceCategory.newObject(withName: categoryName) {
                            numberCategoriesCreated += 1
                            placeCategory = newPlaceCategory
                        }
                        else {
                            numberCategoryCreationErrors += 1
                        }
                    }
                    
                    coreDataPlace.category = placeCategory
                }
                
                coreDataPlace.userName = restaurant[KEY_USER_NAME] as? String
                
                if let listNames = restaurant[PLACE_KEY_LISTS] as? [String], listNames.count > 0 {
                    for listName in listNames {
                        if let existingListName = PlaceList.getPlaceList(withName: listName) {
                            coreDataPlace.addToLists(existingListName)
                        }
                        else {
                            if let newListName = try? PlaceList.newObject(withName: listName) {
                                coreDataPlace.addToLists(newListName)
                                numberListNamesCreated += 1
                            }
                            else {
                                numberListNameCreationErrors += 1
                            }
                        }
                    }
                }
                
                if let coreDataLocation = try? Location.newObject() {
                    coreDataPlace.addToLocations(coreDataLocation)
                    
                    let iAte = restaurant[KEY_IATE] as? NSNumber
                    coreDataLocation.rating!.meThem = iAte
                    
                    coreDataLocation.address = restaurant[PLACE_KEY_LOCATION] as? String
                    
                    if let rating = restaurant[KEY_RATING] as? Float {
                        coreDataLocation.rating!.rating = rating
                    }
                    
                    // Since the location info was all previously part of the place info, it makes sense to also use the creation date and modification date here.
                    coreDataLocation.creationDate = coreDataPlace.creationDate
                    coreDataLocation.modificationDate = coreDataPlace.modificationDate
                    coreDataLocation.userName = coreDataPlace.userName
                    
                    if let imageNames = restaurant[PLACE_KEY_IMAGES] as? [String], imageNames.count > 0 {
                        for imageName in imageNames {
                            if let newImageName = moveLargeImage(largeImageFileName: imageName) {
                                let newImage = Image.newObject()
                                newImage.fileName = newImageName
                                coreDataLocation.addToImages(newImage)
                            }
                            else {
                                if let name = coreDataPlace.name {
                                    imageErrorDescriptions.append("Place Image error for: \(name)")
                                }
                            }
                        }
                    }
                    
                    if let location = restaurant[PLACE_KEY_COORDS] as? CLLocation {
                        coreDataLocation.location = location
                    }
                }
                
                if let menuItems = restaurant[PLACE_KEY_MENU] as? [[String:Any]], menuItems.count > 0 {
                    add(items: menuItems, to: coreDataPlace)
                }
                
                CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
            }
            
            currentPlaceIndex += 1
            
            if currentPlaceIndex < numberPlaces {
                hud?.setProgress(CGFloat(currentPlaceIndex)/CGFloat(numberPlaces), animated: true)

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    doNextRestaurant()
                }
            }
            else {
                hud?.dismiss(true)
                showStats()
            }
        }
    }
    
    private func showStats() {
        var conversionStats =
            "\(numberPlaces) places, " +
            "\(numberImages) images, " +
            "\(numberItems) items, " +
            "\(numberComments) comments, " +
            "\(numberCategoriesCreated) categories, and " +
            "\(numberListNamesCreated) list names. "
        
        if numberImageErrors > 0 {
            conversionStats += "\nErrors occurred converting \(numberImageErrors) image(s)"
        }
        
        Alert.show(withTitle: "Imported from v1 app: ", message: conversionStats)
    }
    
    private func add(items: [[String: Any]], to place: Place) {
        numberItems += items.count

        for menuItem in items {
            guard let coreDataItem = try? Item.newObject() else {
                Log.msg("Failed creating item!")
                continue
            }
            
            place.addToItems(coreDataItem)
            
            coreDataItem.userName = menuItem[KEY_USER_NAME] as? String
            coreDataItem.name = menuItem[ITEM_KEY_NAME] as? String
            coreDataItem.creationDate = menuItem[KEY_DATE] as? NSDate
            
            // In the new data format we're not putting a me/them attribute at the item level. If there is a me/them given for the menuItem, we're going to keep it only if there are no comments for the item. To do so, we'll create a dummy comment and set its me/them item. We can also put in some comment text to say that this is just a dummy comment and the rating doesn't have meaning.
            
            if let comments = menuItem[ITEM_KEY_COMMENTS] as? [[String: Any]], comments.count > 0 {
                switch commentStyle! {
                case .single:
                    addSingle(comments: comments, to: coreDataItem)
                case .multiple:
                    addMultiple(comments: comments, to: coreDataItem)
                }
            }
            else {
                // No comments.
                if let iAte = menuItem[KEY_IATE] as? NSNumber {
                    // Add the dummy comment for the me/them.
                    if let coreDataComment = try? Comment.newObject() {
                        coreDataItem.addToComments(coreDataComment)
                        coreDataComment.rating!.meThem = iAte
                        coreDataComment.comment = "Only me/them has meaning."
                    }
                }
                
                coreDataItem.modificationDate = coreDataItem.creationDate
            }
            
            coreDataItem.save()
        }
    }
    
    // Each item will have exactly one comment.
    private func addSingle(comments:[[String: Any]], to item: Item) {
        /* In this commenting option, I'm going to collapse multiple comments in the old format into a single comment in the new format.
            I'm going to first sort the comments by date so that when I consolidate the strings, it is from oldest to newest.
        */
        
        var sortedComments = comments
        sortedComments.sort { (dictElem1, dictElem2) -> Bool in
            // Parameter areInIncreasingOrder: A predicate that returns `true` if its first argument should be ordered before its second argument; otherwise, `false`.
            if let date1 = (dictElem1[KEY_DATE] as? NSDate) as Date?,
                let date2 = (dictElem2[KEY_DATE] as? NSDate) as Date? {
                return date1 < date2
            }
            else {
                // I'm not sure what to do here!
                return false
            }
        }
        
        var mostRecentDate:Date?

        if let coreDataComment = try? Comment.newObject() {
            item.addToComments(coreDataComment)
            coreDataComment.rating!.meThem = false
            
            var numberRatings = 0
            
            // We'll average the ratings if there is > 1 existing comment.
            var totalRating:Float = 0
            
            var oldestDate:Date?
            
            var extendedComment = ""
            
            numberComments += comments.count
            
            for comment in sortedComments {
                // Just take the first userName.
                if coreDataComment.userName == nil {
                    coreDataComment.userName = comment[KEY_USER_NAME] as? String
                }
                
                if let currentDate = comment[KEY_DATE] as? NSDate as Date? {
                    if oldestDate == nil {
                        oldestDate = currentDate
                    }
                    else if currentDate < oldestDate! {
                        oldestDate = currentDate
                    }
                    
                    if mostRecentDate == nil {
                        mostRecentDate = currentDate
                    }
                    else if currentDate > mostRecentDate! {
                        mostRecentDate = currentDate
                    }
                }
                
                // If iAte is true on one, keep it that way.
                if let iAte = comment[KEY_IATE] as? Bool {
                    let current = coreDataComment.rating!.meThem as! Bool
                    coreDataComment.rating!.meThem = (current || iAte) as NSNumber
                }
                
                if let rating = comment[KEY_RATING] as? Float {
                    totalRating += rating
                    numberRatings += 1
                }
                
                if let comment = comment[COMMENT_KEY_COMMENT] as? String, comment.count > 0 {
                    if extendedComment.count > 0 {
                        extendedComment += "\n"
                    }
                    
                    extendedComment += comment
                }
                
                if let commentImageName = comment[COMMENT_KEY_IMAGE_FILENAME] as? String {
                    // This image, if any, needs to be moved to the largeImages folder
                    if let newImageName = moveLargeImage(largeImageFileName: commentImageName) {
                        let newImage = Image.newObject()
                        newImage.fileName = newImageName
                        coreDataComment.addToImages(newImage)
                    }
                    else {
                        if let name = item.place?.name {
                            imageErrorDescriptions.append("Comment Image error for: \(name)")
                        }
                    }
                }
            }
            
            coreDataComment.creationDate = oldestDate as NSDate?
            coreDataComment.modificationDate = mostRecentDate as NSDate?
            coreDataComment.comment = extendedComment
            
            if numberRatings > 0 {
                coreDataComment.rating!.rating = totalRating / Float(numberRatings)
            }
        }
        
        item.modificationDate = mostRecentDate as NSDate?
    }
    
    private func addMultiple(comments:[[String: Any]], to item: Item) {
        // Estimate the last modification date of the item from the latest date in the comments.
        var lastModDateEstimate:NSDate?
        
        numberComments += comments.count
        
        for comment in comments {
            guard let coreDataComment = try? Comment.newObject() else {
                continue
            }
            
            item.addToComments(coreDataComment)
            
            coreDataComment.userName = comment[KEY_USER_NAME] as? String
            coreDataComment.creationDate = comment[KEY_DATE] as? NSDate
            
            // This isn't really the last modification date, but we don't have one.
            coreDataComment.modificationDate = coreDataComment.creationDate
            
            let iAte = comment[KEY_IATE] as? NSNumber
            coreDataComment.rating!.meThem = iAte
            
            if let rating = comment[KEY_RATING] as? Float {
                coreDataComment.rating!.rating = rating
            }
            
            coreDataComment.comment = comment[COMMENT_KEY_COMMENT] as? String
            
            if let commentImageName = comment[COMMENT_KEY_IMAGE_FILENAME] as? String {
                // This image, if any, needs to be moved to the largeImages folder
                if let newImageName = moveLargeImage(largeImageFileName: commentImageName) {
                    let newImage = Image.newObject()
                    newImage.fileName = newImageName
                    coreDataComment.addToImages(newImage)
                }
                else {
                    if let name = item.place?.name{
                        imageErrorDescriptions.append("Comment Image error for: \(name)")
                    }
                }
            }
            
            if (nil == lastModDateEstimate) {
                lastModDateEstimate = coreDataComment.creationDate
            }
            else {
                if let currCreationDate = coreDataComment.creationDate as Date?, lastModDateEstimate!.compare(currCreationDate) == .orderedAscending {
                    lastModDateEstimate = coreDataComment.creationDate
                }
            }
        } // end-for
        
        item.modificationDate = lastModDateEstimate
    }
}
