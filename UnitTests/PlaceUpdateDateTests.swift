//
//  PlaceUpdateDateTests.swift
//  UnitTests
//
//  Created by Christopher G Prince on 3/19/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import XCTest
@testable import WhatDidILike
import SMCoreLib

class PlaceUpdateDateTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCheckin() throws {
        let place1 = try Place.newObject()
        
        let location1 = try Location.newObject()
        place1.addToLocations(location1)
        
        let checkin = Checkin.newObject()
        location1.addToCheckin(checkin)
        
        let lastDate = place1.lastExportModificationDate
        
        XCTAssert(lastDate == checkin.date)
    }
    
    func testPlaceList() throws {
        let place1 = try Place.newObject()
        
        let lastDate1 = place1.lastExportModificationDate

        guard let placeList = try? PlaceList.newObject(withName: "foo") else {
            XCTFail()
            return
        }
        
        place1.addToLists(placeList)
        
        // Should update modification date of place
        place1.save()
        
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testPlaceListChange() throws {
        let place1 = try Place.newObject()
                
        guard let placeList = try? PlaceList.newObject(withName: "foo") else {
            XCTFail()
            return
        }
        
        place1.addToLists(placeList)
        
        place1.save()
        
        let lastDate1 = place1.lastExportModificationDate

        placeList.name = "foo bar"
        placeList.save()
        
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testPlaceCategory() throws {
        let place1 = try Place.newObject()
        
        let lastDate1 = place1.lastExportModificationDate

        guard let placeCategory = try? PlaceCategory.newObject(withName: "foo") else {
            XCTFail()
            return
        }
        
        place1.category = placeCategory
        
        // Should update modification date of place
        place1.save()
        
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testPlaceCategoryChange() throws {
        let place1 = try Place.newObject()
                
        guard let placeCategory = try? PlaceCategory.newObject(withName: "foo") else {
            XCTFail()
            return
        }
        
        place1.category = placeCategory
        
        place1.save()
        let lastDate1 = place1.lastExportModificationDate

        placeCategory.name = "foo bar"
        placeCategory.save()

        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testItem() throws {
        let place1 = try Place.newObject()
    
        let lastDate1 = place1.lastExportModificationDate

        let item = try Item.newObject()
        place1.addToItems(item)
        
        // Should update modification date of place
        place1.save()
        
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        // Also removes item(s)
        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testItemChange() throws {
        let place1 = try Place.newObject()
    
        let item = try Item.newObject()
        place1.addToItems(item)
        
        place1.save()
        
        let lastDate1 = place1.lastExportModificationDate

        item.name = "Foo"
        item.save()
        
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        // Also removes item(s)
        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testComment() throws {
        let place1 = try Place.newObject()
    
        let item = try Item.newObject()
        place1.addToItems(item)
        place1.save()
        
        let lastDate1 = place1.lastExportModificationDate

        let comment = try Comment.newObject()
        item.addToComments(comment)
        place1.save()

        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        // Also removes item(s)
        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testCommentChange() throws {
        let place1 = try Place.newObject()
    
        let item = try Item.newObject()
        place1.addToItems(item)
        place1.save()

        let comment = try Comment.newObject()
        item.addToComments(comment)
        place1.save()
        
        let lastDate1 = place1.lastExportModificationDate

        comment.comment = "stuff"
        comment.save()
        
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        // Also removes item(s)
        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testLocation() throws {
        let place1 = try Place.newObject()
        place1.save()
        
        let lastDate1 = place1.lastExportModificationDate

        let location = try Location.newObject()
        place1.addToLocations(location)
        place1.save()

        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testLocationChange() throws {
        let place1 = try Place.newObject()
        
        let location = try Location.newObject()
        place1.addToLocations(location)
        place1.save()
        
        let lastDate1 = place1.lastExportModificationDate

        location.address = "123 Easy St."
        location.save()

        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testImage() throws {
        let place1 = try Place.newObject()
        
        let location = try Location.newObject()
        place1.addToLocations(location)

        place1.save()
        let lastDate1 = place1.lastExportModificationDate

        let image = Image.newObject()
        image.fileName = "path"
        location.addToImages(image)
        
        place1.save()
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testRating() throws {
        let place1 = try Place.newObject()
    
        let rating = Rating.newObject()

        let location = try Location.newObject()
        place1.addToLocations(location)
        place1.save()

        let lastDate1 = place1.lastExportModificationDate

        location.rating = rating
        place1.save()
        
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testRatingChange() throws {
        let place1 = try Place.newObject()
    
        let rating = Rating.newObject()

        let location = try Location.newObject()
        place1.addToLocations(location)
        place1.save()

        location.rating = rating
        place1.save()
        
        let lastDate1 = place1.lastExportModificationDate

        rating.recommendedBy = "joe"
        place1.save()
        
        let lastDate2 = place1.lastExportModificationDate

        XCTAssert(lastDate1 < lastDate2)

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}
