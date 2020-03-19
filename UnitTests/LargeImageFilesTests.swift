//
//  LargeImageFilesTests.swift
//  UnitTests
//
//  Created by Christopher G Prince on 3/19/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import XCTest
@testable import WhatDidILike

class LargeImageFilesTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testImages() {
        let image1 = Image.newObject()
        let fileName = "Foo"
        image1.fileName = fileName
        
        XCTAssert(image1.largeImageFiles == [fileName])
    }
    
    func testComments() {
        let comment = Comment.newObject()
        
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        comment.addToImages(image)
        
        XCTAssert(comment.largeImageFiles == [fileName])
        
        let fileName2 = "Foo Bar"
        let image2 = Image.newObject()
        image2.fileName = fileName2
        comment.addToImages(image2)
        
        XCTAssert(comment.largeImageFiles == [fileName, fileName2])
    }
    
    func testLocations() {
        let location1 = Location.newObject()
        
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        location1.addToImages(image)
        
        XCTAssert(location1.largeImageFiles == [fileName])

        let fileName2 = "Fooby"
        let image2 = Image.newObject()
        image2.fileName = fileName2
        location1.addToImages(image2)
        
        XCTAssert(location1.largeImageFiles == [fileName, fileName2])
    }
    
    func testItems() {
        let item = Item.newObject()
        
        let comment = Comment.newObject()
    
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        comment.addToImages(image)
        
        item.addToComments(comment)
        
        XCTAssert(item.largeImageFiles == [fileName])
        
        let comment2 = Comment.newObject()
    
        let fileName2 = "Foo"
        let image2 = Image.newObject()
        image2.fileName = fileName2
        comment2.addToImages(image2)
        
        item.addToComments(comment2)
        
        XCTAssert(item.largeImageFiles == [fileName, fileName2])
    }
    
    func testPlaces() {
        let place = Place.newObject()
        
        let item = Item.newObject()
        
        let comment = Comment.newObject()
    
        let fileName = "Foo"
        let image = Image.newObject()
        image.fileName = fileName
        comment.addToImages(image)
        
        item.addToComments(comment)
        
        XCTAssert(item.largeImageFiles == [fileName])
        
        let comment2 = Comment.newObject()
    
        let fileName2 = "Foo"
        let image2 = Image.newObject()
        image2.fileName = fileName2
        comment2.addToImages(image2)
        
        item.addToComments(comment2)
        
        place.addToItems(item)
        
        XCTAssert(place.largeImageFiles == [fileName, fileName2])
        
        let location1 = Location.newObject()
        
        let fileName3 = "Foo"
        let image3 = Image.newObject()
        image3.fileName = fileName3
        location1.addToImages(image3)
        
        let fileName4 = "Fooby"
        let image4 = Image.newObject()
        image4.fileName = fileName4
        location1.addToImages(image4)
        
        place.addToLocations(location1)
        
        XCTAssert(place.largeImageFiles == [fileName, fileName2, fileName3, fileName4])
    }
}
