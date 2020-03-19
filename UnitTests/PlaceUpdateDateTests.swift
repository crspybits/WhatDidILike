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

    func testCheckin() {
        let place1 = Place.newObject()
        
        let location1 = Location.newObject()
        place1.addToLocations(location1)
        
        let checkin = Checkin.newObject()
        location1.addToCheckin(checkin)
        
        let dates = place1.dates.sorted()
        
        XCTAssert(dates[dates.count-1] == checkin.date)
    }
    
    func testPlaceList() {
        let place1 = Place.newObject()
        
        let dates1 = place1.dates.sorted()
        
        guard let placeList = try? PlaceList.newObject(withName: "foo") else {
            XCTFail()
            return
        }
        
        place1.addToLists(placeList)
        
        // Should update modification date of place
        place1.save()
        
        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testPlaceListChange() {
        let place1 = Place.newObject()
                
        guard let placeList = try? PlaceList.newObject(withName: "foo") else {
            XCTFail()
            return
        }
        
        place1.addToLists(placeList)
        
        place1.save()
        
        let dates1 = place1.dates.sorted()

        placeList.name = "foo bar"
        placeList.save()
        
        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testPlaceCategory() {
        let place1 = Place.newObject()
        
        let dates1 = place1.dates.sorted()
        
        guard let placeCategory = try? PlaceCategory.newObject(withName: "foo") else {
            XCTFail()
            return
        }
        
        place1.category = placeCategory
        
        // Should update modification date of place
        place1.save()
        
        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testPlaceCategoryChange() {
        let place1 = Place.newObject()
                
        guard let placeCategory = try? PlaceCategory.newObject(withName: "foo") else {
            XCTFail()
            return
        }
        
        place1.category = placeCategory
        
        place1.save()
        let dates1 = place1.dates.sorted()
        
        placeCategory.name = "foo bar"
        placeCategory.save()

        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testItem() {
        let place1 = Place.newObject()
    
        let dates1 = place1.dates.sorted()
        
        let item = Item.newObject()
        place1.addToItems(item)
        
        // Should update modification date of place
        place1.save()
        
        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        // Also removes item(s)
        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testItemChange() {
        let place1 = Place.newObject()
    
        let item = Item.newObject()
        place1.addToItems(item)
        
        place1.save()
        
        let dates1 = place1.dates.sorted()

        item.name = "Foo"
        item.save()
        
        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        // Also removes item(s)
        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testComment() {
        let place1 = Place.newObject()
    
        let item = Item.newObject()
        place1.addToItems(item)
        place1.save()
        
        let dates1 = place1.dates.sorted()

        let comment = Comment.newObject()
        item.addToComments(comment)
        place1.save()

        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        // Also removes item(s)
        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testCommentChange() {
        let place1 = Place.newObject()
    
        let item = Item.newObject()
        place1.addToItems(item)
        place1.save()

        let comment = Comment.newObject()
        item.addToComments(comment)
        place1.save()
        
        let dates1 = place1.dates.sorted()

        comment.comment = "stuff"
        comment.save()
        
        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        // Also removes item(s)
        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testLocation() {
        let place1 = Place.newObject()
        place1.save()
        
        let dates1 = place1.dates.sorted()

        let location = Location.newObject()
        place1.addToLocations(location)
        place1.save()

        let dates2 = place1.dates.sorted()

        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testLocationChange() {
        let place1 = Place.newObject()
        
        let location = Location.newObject()
        place1.addToLocations(location)
        place1.save()
        
        let dates1 = place1.dates.sorted()
        
        location.address = "123 Easy St."
        location.save()

        let dates2 = place1.dates.sorted()

        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testImage() {
        let place1 = Place.newObject()
        
        let location = Location.newObject()
        place1.addToLocations(location)

        place1.save()
        let dates1 = place1.dates.sorted()

        let image = Image.newObject()
        image.fileName = "path"
        location.addToImages(image)
        
        place1.save()
        let dates2 = place1.dates.sorted()

        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testRating() {
        let place1 = Place.newObject()
    
        let rating = Rating.newObject()

        let location = Location.newObject()
        place1.addToLocations(location)
        place1.save()

        let dates1 = place1.dates.sorted()

        location.rating = rating
        place1.save()
        
        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testRatingChange() {
        let place1 = Place.newObject()
    
        let rating = Rating.newObject()

        let location = Location.newObject()
        place1.addToLocations(location)
        place1.save()

        location.rating = rating
        place1.save()
        
        let dates1 = place1.dates.sorted()

        rating.recommendedBy = "joe"
        place1.save()
        
        let dates2 = place1.dates.sorted()
        
        XCTAssert(dates1[dates1.count-1] < dates2[dates2.count-1] )

        place1.remove()
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}
