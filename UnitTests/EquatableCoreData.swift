//
//  EquatableCoreData.swift
//  UnitTests
//
//  Created by Christopher G Prince on 3/18/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import XCTest
@testable import WhatDidILike
import SMCoreLib

class EquatableCoreData: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCheckinEquality() {
        let checkin1 = Checkin.newObject()
        
        let checkin2 = Checkin.newObject()
        checkin2.date = checkin1.date
        
        XCTAssert(Checkin.equal(checkin1, checkin2))
        XCTAssert(Checkin.equal(checkin1, checkin1))

        checkin2.date = checkin1.date! + 100
        XCTAssert(!Checkin.equal(checkin1, checkin2))
                
        let set1 = Set<Checkin>([checkin1])
        XCTAssert(Checkin.equal(set1, set1))

        XCTAssert(!Checkin.equal(nil, set1))

        let set2 = Set<Checkin>([checkin2])
        XCTAssert(!Checkin.equal(set2, set1))
    }
    
    func testPlaceListEquality() {
        let placeList1 = try! PlaceList.newObject(withName: "foo")
        let placeList2 = try! PlaceList.newObject(withName: "bar")
        
        XCTAssert(!PlaceList.equal(placeList1, placeList2))
        XCTAssert(PlaceList.equal(placeList1, placeList1))
    }
    
    func testPlaceCategoryEquality() {
        let placeCategory1 = try! PlaceCategory.newObject(withName: "foo")
        let placeCategory2 = try! PlaceCategory.newObject(withName: "bar")
    
        XCTAssert(!PlaceCategory.equal(placeCategory1, placeCategory2))
        XCTAssert(PlaceCategory.equal(placeCategory1, placeCategory1))
    }
    
    func testItemEquality() {
        let item1 = Item.newObject()
        item1.name = "item1"
        let item2 = Item.newObject()
        item2.name = "item2"
        
        XCTAssert(!(Item.equal(item1, item2)))
        
        let item3 = Item.newObject()
        item3.name = "item1"
        
        XCTAssert(Item.equal(item1, item3))
    }
    
    func testRatingEquality() {
        let rating1 = Rating.newObject()
        rating1.rating = 0.1
        rating1.meThem = true
        rating1.again = false
        rating1.recommendedBy = "foo"

        let rating2 = Rating.newObject()
        rating2.rating = 0.1
        rating2.meThem = true
        rating2.again = false
        rating2.recommendedBy = "foo"
        
        XCTAssert(Rating.equal(rating1, rating2))
        
        let rating3 = Rating.newObject()
        rating3.rating = 0.1
        rating3.meThem = true
        rating3.again = false
        rating3.recommendedBy = "foo"
        
        rating3.rating = 0.2
        XCTAssert(!(Rating.equal(rating1, rating3)))
    }
    
    func testImageEquality() {
        let image1 = Image.newObject()
        image1.fileName = "foo"
        
        let image2 = Image.newObject()
        image2.fileName = "foo"
        
        XCTAssert(Image.equal(image1, image2))
        
        let image3 = Image.newObject()
        image3.fileName = "foo bar"
        XCTAssert(!Image.equal(image1, image3))
    }
    
    func testImagesEquality() {
        let image1 = Image.newObject()
        image1.fileName = "foo"
        let image2 = Image.newObject()
        image2.fileName = "foo"
        let image3 = Image.newObject()
        image3.fileName = "foo bar"
        
        XCTAssert(Image.equal(nil, nil))
        XCTAssert(!Image.equal(nil, [Image]()))
        XCTAssert(!Image.equal(nil, [image1]))

        XCTAssert(Image.equal([image1], [image1]))
        XCTAssert(Image.equal([image2], [image1]))
        XCTAssert(!Image.equal([image3], [image1]))
        XCTAssert(!Image.equal([image2, image3], [image1]))
    }
    
    func testCommentEquality() {
        let image1 = Image.newObject()
        image1.fileName = "foo"
 
        let image2 = Image.newObject()
        image2.fileName = "foo bar"
 
        let rating1 = Rating.newObject()
        rating1.rating = 0.1
        rating1.meThem = true
        rating1.again = false
        rating1.recommendedBy = "foo"
        
        let item1 = Item.newObject()
        item1.name = "item1"
    
        let comment1 = Comment.newObject()
        comment1.comment = "margba"
        comment1.addToImages(image1)
        comment1.rating = rating1
        comment1.item = item1
        
        let comment2 = Comment.newObject()
        comment2.comment = "margba"
        comment2.addToImages(image1)
        comment2.addToImages(image2)
        comment2.rating = rating1
        comment2.item = item1
        
        XCTAssert(Comment.equal(comment1, comment1))
        XCTAssert(!Comment.equal(comment1, comment2))
    }
    
    func testLocation() {
        let location1 = Location.newObject()
        location1.address = "123 XWay St."
        location1.location = CLLocation(latitude: 1.23, longitude: 30.4)
        location1.specificDescription = "foo"
        
        let image1 = Image.newObject()
        image1.fileName = "foo"
        
        location1.images = NSOrderedSet(array: [image1])
        
        let rating1 = Rating.newObject()
        rating1.rating = 0.1
        rating1.meThem = true
        rating1.again = false
        rating1.recommendedBy = "foo"
        
        location1.rating = rating1
        
        let checkin1 = Checkin.newObject()
        location1.addToCheckin(checkin1)
        
        let location2 = Location.newObject()
        let checkin2 = Checkin.newObject()
        location2.addToCheckin(checkin2)

        XCTAssert(!Location.equal(nil, location1))
        XCTAssert(Location.equal(location1, location1))
        XCTAssert(!Location.equal(location2, location1))
    }
    
    func testEqualityOnLivePlaces() {
        guard let places = Place.fetchAllObjects() else {
            XCTFail()
            return
        }
        
        guard places.count > 0 else {
            return
        }
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        var success = 0
        
        for place in places {
            guard let data1 = try? encoder.encode(place) else {
                XCTFail()
                return
            }
            
            guard let place2 = try? decoder.decode(Place.self, from: data1) else {
                XCTFail()
                return
            }
                       
            if !Place.equal(place, place2) {
                XCTFail("json1: \(String(describing: String(data: data1, encoding: .utf8)))")
                
                if let data2 = try? encoder.encode(place2) {
                    XCTFail("json2: \(String(describing: String(data: data2, encoding: .utf8)))")
                }
            }
            else {
                success += 1
            }
                        
            CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
        }
        
        Log.msg("Succeeded with \(success) places; failed with \(places.count - success) places.")
    }
}
