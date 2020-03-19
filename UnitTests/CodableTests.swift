//
//  CodableTests.swift
//  UnitTests
//
//  Created by Christopher G Prince on 3/16/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

// Don't test this with the app running a device. Breaks build. Not sure why.

import XCTest
@testable import WhatDidILike
import SMCoreLib

class CodableTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPlace() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(place1.generalDescription == place2.generalDescription)
        XCTAssert(place1.name == place2.name)
        XCTAssert(place1.category == nil)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    func testPlaceWithOnePlaceCategory() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        
        let placeCategoryName = "Foo Biz"
        guard let placeCategory1 = try? PlaceCategory.newObject(withName: placeCategoryName) else {
            XCTFail()
            return
        }
        
        place1.category = placeCategory1
        
        XCTAssert(placeCategory1.places?.count == 1)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(place1.generalDescription == place2.generalDescription)
        XCTAssert(place1.name == place2.name)
        XCTAssert(place2.category == placeCategory1)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory1)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    func testPlaceCategoryDeletingFirst() {
        let name = "Foo"
        guard let placeCategory1 = try? PlaceCategory.newObject(withName: name) else {
            XCTFail()
            return
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(placeCategory1) else {
            XCTFail()
            return
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory1)
        
        let decoder = JSONDecoder()
        guard let placeCategory2 = try? decoder.decode(PlaceCategory.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(name == placeCategory2.name)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory2)
    }
    
    func testPlaceCategoryWithoutDeletingFirst() {
        let name = "Foo"
        guard let placeCategory1 = try? PlaceCategory.newObject(withName: name) else {
            XCTFail()
            return
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(placeCategory1) else {
            XCTFail()
            return
        }
                
        let decoder = JSONDecoder()
        guard let placeCategory2 = try? decoder.decode(PlaceCategory.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(placeCategory2.name == nil)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory2)
    }
    
    func testDecodeFirstInstanceOfLocationInPlace() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        place1.category = try? PlaceCategory.newObject(withName: "Baz")
        
        guard place1.category != nil else {
            XCTFail()
            return
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(place1.generalDescription == place2.generalDescription)
        XCTAssert(place1.name == place2.name)
        XCTAssert(place1.category == place2.category, "Error: \(String(describing: place2.category))")
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1.category!)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    func testDecodeSecondInstanceOfLocationInPlace() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        place1.category = try? PlaceCategory.newObject(withName: "Baz")
        
        guard place1.category != nil else {
            XCTFail()
            return
        }
        
        let encoder = JSONEncoder()
        guard let data1 = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let place2 = Place.newObject()
        place2.generalDescription = "Foo2"
        place2.name = "Bar2"
        place2.category = place1.category
        
        guard let data2 = try? encoder.encode(place2) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place1b = try? decoder.decode(Place.self, from: data1) else {
            XCTFail()
            return
        }
        
        guard let place2b = try? decoder.decode(Place.self, from: data2) else {
            XCTFail()
            return
        }
        
        XCTAssert(place1.generalDescription == place1b.generalDescription)
        XCTAssert(place2.generalDescription == place2b.generalDescription)

        XCTAssert(place1.name == place1b.name)
        XCTAssert(place2.name == place2b.name)

        XCTAssert(place1.category == place1b.category)
        XCTAssert(place2.category == place2b.category)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName)
            .remove(place1.category!)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1b)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2b)
    }
    
    func testPlaceWithOneItem() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        
        let item1 = Item.newObject()
        let name1 = "foo"
        item1.name = name1
        place1.addToItems(item1)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(place1.generalDescription == place2.generalDescription)
        XCTAssert(place1.name == place2.name)
        XCTAssert(place1.category == nil)
        
        guard let items2 = place2.items?.array as? [Item],
            items2.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(items2[0].name == name1)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(items2[0])

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    func testPlaceWithTwoItems() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        
        let item1 = Item.newObject()
        let name1 = "foo"
        item1.name = name1
        place1.addToItems(item1)
        
        let item2 = Item.newObject()
        let name2 = "foo barr"
        item2.name = name2
        place1.addToItems(item2)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(place1.generalDescription == place2.generalDescription)
        XCTAssert(place1.name == place2.name)
        XCTAssert(place1.category == nil)
        
        guard let items2 = place2.items?.array as? [Item],
            items2.count == 2 else {
            XCTFail()
            return
        }
        
        XCTAssert(items2[0].name == name1)
        XCTAssert(items2[1].name == name2)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item2)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(items2[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(items2[1])

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    func testPlaceWithOnePlaceList() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        
        let placeListName1 = "barfle"
        guard let placeList1 = try? PlaceList.newObject(withName: placeListName1) else {
            XCTFail()
            return
        }
        
        place1.addToLists(placeList1)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(place1.generalDescription == place2.generalDescription)
        XCTAssert(place1.name == place2.name)
        XCTAssert(place1.category == nil)
        
        guard let placeListsSet = (place2.lists as? Set<PlaceList>) else {
            XCTFail()
            return
        }
        
        let placeListArray = Array(placeListsSet)
        guard placeListArray.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(placeListArray[0].name == placeListName1)
        
        // I think this ought to happen normally, automatically, when the place is removed but force it because I want to quickly test.
        placeListArray[0].removeFromPlaces(place1)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        
        guard let placesForPlaceListSet = placeListArray[0].places as? Set<Place> else {
            XCTFail()
            return
        }
        
        let placesForPlaceListSetArray = Array(placesForPlaceListSet)
        XCTAssert(placesForPlaceListSetArray.count == 1)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeListArray[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    func testPlaceWithTwoPlaceLists() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        
        let placeListName1 = "barfle"
        guard let placeList1 = try? PlaceList.newObject(withName: placeListName1) else {
            XCTFail()
            return
        }
        
        place1.addToLists(placeList1)
        
        let placeListName2 = "barfle warfle"
        guard let placeList2 = try? PlaceList.newObject(withName: placeListName2) else {
            XCTFail()
            return
        }
        
        place1.addToLists(placeList2)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(place1.generalDescription == place2.generalDescription)
        XCTAssert(place1.name == place2.name)
        XCTAssert(place1.category == nil)
        
        guard let placeListsSet = (place2.lists as? Set<PlaceList>) else {
            XCTFail()
            return
        }
        
        let placeListArray = Array(placeListsSet).sorted { (pl1, pl2) -> Bool in
            if let name1 = pl1.name, let name2 = pl2.name {
                return name1 < name2
            }
            else {
                return false
            }
        }
        
        guard placeListArray.count == 2 else {
            XCTFail()
            return
        }
        
        XCTAssert(placeListArray[0].name == placeListName1)
        XCTAssert(placeListArray[1].name == placeListName2)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList2)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeListArray[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeListArray[1])

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    func testTwoPlacesWithPlaceListDuplicatedAcrossPlaces() {
        let place1 = Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        
        let place2 = Place.newObject()
        place2.generalDescription = "Foo2"
        place2.name = "Bar2"
        
        let placeListName = "barfle"
        guard let placeList = try? PlaceList.newObject(withName: placeListName) else {
            XCTFail()
            return
        }
        
        place1.addToLists(placeList)
        place2.addToLists(placeList)
        
        let encoder = JSONEncoder()
        guard let data1 = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        guard let data2 = try? encoder.encode(place2) else {
            XCTFail()
            return
        }
        
        // We have the places and place list encoded in data. Delete them to test their decoding.
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
        
        let decoder = JSONDecoder()
        guard let place1b = try? decoder.decode(Place.self, from: data1) else {
            XCTFail()
            return
        }
        
        guard let place2b = try? decoder.decode(Place.self, from: data2) else {
            XCTFail()
            return
        }
        
        guard let placeListsSet1b = (place1b.lists as? Set<PlaceList>) else {
            XCTFail()
            return
        }
        
        let placeListArray1b = Array(placeListsSet1b)
        guard placeListArray1b.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(placeListArray1b[0].name == placeListName)
        
        guard let placeListsSet2b = (place2b.lists as? Set<PlaceList>) else {
            XCTFail()
            return
        }
        
        let placeListArray2b = Array(placeListsSet2b)
        guard placeListArray2b.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(placeListArray2b[0].name == placeListName)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeListArray1b[0])

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1b)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2b)
    }
    
    func testImage() {
        let image = Image.newObject()
        image.fileName = "Foo"
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(image) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let image2 = try? decoder.decode(Image.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(image.fileName == image2.fileName)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(image)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(image2)
    }
    
    func testRating() {
        let rating = Rating.newObject()
        rating.again = true
        rating.meThem = true
        rating.rating = 0.4
        rating.recommendedBy = "Foo Bar"
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(rating) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let rating2 = try? decoder.decode(Rating.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(rating.again?.boolValue == rating2.again?.boolValue)
        XCTAssert(rating.meThem?.boolValue == rating2.meThem?.boolValue)
        XCTAssert(rating.rating == rating2.rating)
        XCTAssert(rating.recommendedBy == rating2.recommendedBy)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(rating)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(rating2)
    }
    
    func testCommentWithNoImages() {
        let comment = Comment.newObject()
        comment.comment = "Some stuff"
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(comment) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let comment2 = try? decoder.decode(Comment.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(comment.comment == comment2.comment)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment2)
    }
    
    func testCommentWithOneImage() {
        let comment = Comment.newObject()
        comment.comment = "Some stuff"
        
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        
        comment.addToImages(image)
        XCTAssert(comment.images != nil)

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(comment) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let comment2 = try? decoder.decode(Comment.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(comment.comment == comment2.comment)
        
        guard let images = comment.images?.array as? [Image],
            images.count == 1 else {
            XCTFail()
            return
        }
        
        guard let images2 = comment2.images?.array as? [Image],
            images2.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(images[0].fileName == fileName)
        XCTAssert(images2[0].fileName == fileName)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images2[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment2)
    }
    
    func testCommentWithTwoImages() {
        let comment = Comment.newObject()
        let commentText = "Some stuff"
        comment.comment = commentText
        
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        comment.addToImages(image)
        
        let fileName2 = "Foo Bar"
        let image2 = Image.newObject()
        image2.fileName = fileName2
        comment.addToImages(image2)
        
        XCTAssert(comment.images?.array.count == 2)

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(comment) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let comment2 = try? decoder.decode(Comment.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(comment.comment == commentText)
        XCTAssert(comment2.comment == commentText)
        
        guard let images = comment.images?.array as? [Image],
            images.count == 2 else {
            XCTFail()
            return
        }
        
        guard let images2 = comment2.images?.array as? [Image],
            images2.count == 2 else {
            XCTFail()
            return
        }
        
        XCTAssert(images[0].fileName == fileName)
        XCTAssert(images2[0].fileName == fileName)
        XCTAssert(images[1].fileName == fileName2)
        XCTAssert(images2[1].fileName == fileName2)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images2[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images[1])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images2[1])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment2)
    }
    
    func testCommentWithRating() {
        let comment = Comment.newObject()
        comment.comment = "Some stuff"
        
        let rating = Rating.newObject()
        rating.again = true
        rating.meThem = true
        rating.rating = 0.4
        rating.recommendedBy = "Foo Bar"

        comment.rating = rating
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(comment) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let comment2 = try? decoder.decode(Comment.self, from: data) else {
            XCTFail()
            return
        }
        
        guard let rating2 = comment2.rating else {
            XCTFail()
            return
        }
        
        XCTAssert(comment.comment == comment2.comment)
        
        XCTAssert(rating.again?.boolValue == rating2.again?.boolValue)
        XCTAssert(rating.meThem?.boolValue == rating2.meThem?.boolValue)
        XCTAssert(rating.rating == rating2.rating)
        XCTAssert(rating.recommendedBy == rating2.recommendedBy)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(rating)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(rating2)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment2)
    }
    
    func testItemWithNoComment() {
        let item = Item.newObject()
        let name = "foo"
        item.name = name
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(item) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let item2 = try? decoder.decode(Item.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(item2.name == name)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item2)
    }
    
    func testItemWithOneComment() {
        let item = Item.newObject()
        let name = "foo"
        item.name = name
        
        let comment = Comment.newObject()
        let commentText = "Some stuff"
        comment.comment = commentText
        item.addToComments(comment)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(item) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let item2 = try? decoder.decode(Item.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(item2.name == name)
        
        guard let comments = item2.comments?.array as? [Comment],
            comments.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(comments[0].comment == commentText)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comments[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item2)
    }
    
    func testItemWithTwoComments() {
        let item = Item.newObject()
        let name = "foo"
        item.name = name

        let comment = Comment.newObject()
        let commentText = "Some stuff"
        comment.comment = commentText
        item.addToComments(comment)
        
        let comment2 = Comment.newObject()
        let commentText2 = "Some more stuff"
        comment2.comment = commentText2
        item.addToComments(comment2)

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(item) else {
            XCTFail()
            return
        }

        let decoder = JSONDecoder()
        guard let item2 = try? decoder.decode(Item.self, from: data) else {
            XCTFail()
            return
        }

        XCTAssert(item2.name == name)

        guard let comments = item2.comments?.array as? [Comment],
            comments.count == 2 else {
            XCTFail()
            return
        }

        XCTAssert(comments[0].comment == commentText)
        XCTAssert(comments[1].comment == commentText2)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment2)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comments[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comments[1])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item2)
    }
    
    func testItemWithCommentAndImage() {
        let item = Item.newObject()
        let name = "foo"
        item.name = name

        let comment = Comment.newObject()
        let commentText = "Some stuff"
        comment.comment = commentText
        item.addToComments(comment)
        
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        comment.addToImages(image)
        
        guard let images = comment.images?.array as? [Image],
            images.count == 1 else {
            XCTFail()
            return
        }

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(item) else {
            XCTFail()
            return
        }

        let decoder = JSONDecoder()
        guard let item2 = try? decoder.decode(Item.self, from: data) else {
            XCTFail()
            return
        }

        XCTAssert(item2.name == name)

        guard let comments2 = item2.comments?.array as? [Comment],
            comments2.count == 1 else {
            XCTFail()
            return
        }
        
        let images2 = (comments2.map {$0.images?.array as? [Image]}.compactMap {$0}.flatMap {$0})
        
        guard images2.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(images2[0].fileName == fileName)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images2[0])

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comment)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(comments2[0])
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(item2)
    }
    
    func testLocation() {
        let location1 = Location.newObject()
        let address = "123 Easy St."
        location1.address = address
        let clLocation = CLLocation(latitude: 1.12, longitude: 2.23)
        location1.location = clLocation
        let specificDescription = "stuff"
        location1.specificDescription = specificDescription
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(location1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let location2 = try? decoder.decode(Location.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(location2.address == address)
        XCTAssert(location2.location?.coordinate.latitude == clLocation.coordinate.latitude)
        XCTAssert(location2.location?.coordinate.longitude == clLocation.coordinate.longitude)
        XCTAssert(location2.specificDescription == specificDescription)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location2)
    }
    
    func testLocationWithOneImage() {
        let location1 = Location.newObject()
        
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        
        location1.addToImages(image)
        XCTAssert(location1.images != nil)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(location1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let location2 = try? decoder.decode(Location.self, from: data) else {
            XCTFail()
            return
        }
        
        guard let images = location2.images?.array as? [Image],
            images.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(images[0].fileName == fileName)
        XCTAssert(images[0].location == location2)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(image)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images[0])

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location2)
    }
    
    func testLocationWithTwoImages() {
        let location = Location.newObject()
        
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        location.addToImages(image)
        
        let fileName2 = "Foo Bar"
        let image2 = Image.newObject()
        image2.fileName = fileName2
        location.addToImages(image2)
        
        XCTAssert(location.images?.array.count == 2)

        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(location) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let location2 = try? decoder.decode(Location.self, from: data) else {
            XCTFail()
            return
        }
        
        guard let images2 = location2.images?.array as? [Image],
            images2.count == 2 else {
            XCTFail()
            return
        }
        
        XCTAssert(images2[0].fileName == fileName)
        XCTAssert(images2[1].fileName == fileName2)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(image)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(image2)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images2[0])
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(images2[1])
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location2)
    }
    
    func testLocationWithRating() {
        let location = Location.newObject()
        
        let rating = Rating.newObject()
        rating.again = true
        rating.meThem = true
        rating.rating = 0.4
        rating.recommendedBy = "Foo Bar"

        location.rating = rating
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(location) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let location2 = try? decoder.decode(Location.self, from: data) else {
            XCTFail()
            return
        }
        
        guard let rating2 = location2.rating else {
            XCTFail()
            return
        }
                
        XCTAssert(rating.again?.boolValue == rating2.again?.boolValue)
        XCTAssert(rating.meThem?.boolValue == rating2.meThem?.boolValue)
        XCTAssert(rating.rating == rating2.rating)
        XCTAssert(rating.recommendedBy == rating2.recommendedBy)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(rating)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(rating2)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location2)
    }
    
    func testLocationWithOneCheckin() {
        let location1 = Location.newObject()
        
        let checkin = Checkin.newObject()
        XCTAssert(checkin.date != nil)
        location1.addToCheckin(checkin)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(location1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let location2 = try? decoder.decode(Location.self, from: data) else {
            XCTFail()
            return
        }
        
        guard let checkinsSet = location2.checkin as? Set<Checkin> else {
            XCTFail()
            return
        }
        
        let checkinArray = Array(checkinsSet)
        
        guard checkinArray.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(checkinArray[0].date == checkin.date)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location2)
    }
    
    func testLocationWithTwoCheckins() {
        let location1 = Location.newObject()
        
        let checkin = Checkin.newObject()
        XCTAssert(checkin.date != nil)
        location1.addToCheckin(checkin)
        
        let checkin2 = Checkin.newObject()
        XCTAssert(checkin2.date != nil)
        location1.addToCheckin(checkin2)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(location1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let location2 = try? decoder.decode(Location.self, from: data) else {
            XCTFail()
            return
        }
        
        guard let checkinsSet = location2.checkin as? Set<Checkin> else {
            XCTFail()
            return
        }
        
        let checkinArray = Array(checkinsSet).sorted(by: {c1, c2 in
            if let d1 = c1.date, let d2 = c2.date {
                return d1 < d2
            }
            else {
                return false
            }
        })
        
        guard checkinArray.count == 2 else {
            XCTFail()
            return
        }
        
        XCTAssert(checkinArray[0].date == checkin.date)
        XCTAssert(checkinArray[1].date == checkin2.date)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location2)
    }
    
    func testCheckin() {
        let checkin = Checkin.newObject()
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(checkin) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let checkin2 = try? decoder.decode(Checkin.self, from: data) else {
            XCTFail()
            return
        }
        
        XCTAssert(checkin.date == checkin2.date)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(checkin)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(checkin2)
    }
    
    func testPlaceWithOneLocation() {
        let place1 = Place.newObject()
        
        let location1 = Location.newObject()
        place1.addToLocations(location1)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        guard let locationsSet2 = place2.locations as? Set<Location> else {
            XCTFail()
            return
        }
        
        let locationsArray2 = Array(locationsSet2)

        XCTAssert(locationsArray2.count == 1)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    func testPlaceWithTwoLocations() {
        let place1 = Place.newObject()
        
        let location1 = Location.newObject()
        place1.addToLocations(location1)

        let location2 = Location.newObject()
        place1.addToLocations(location2)
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(place1) else {
            XCTFail()
            return
        }
        
        let decoder = JSONDecoder()
        guard let place2 = try? decoder.decode(Place.self, from: data) else {
            XCTFail()
            return
        }
        
        guard let locationsSet2 = place2.locations as? Set<Location> else {
            XCTFail()
            return
        }
        
        let locationsArray2 = Array(locationsSet2)

        XCTAssert(locationsArray2.count == 2)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
}
