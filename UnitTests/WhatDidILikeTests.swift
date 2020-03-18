//
//  WhatDidILikeTests.swift
//  WhatDidILikeTests
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import XCTest
@testable import WhatDidILike
import SMCoreLib

// Don't test this with the app running a device. Breaks build. Not sure why.

class WhatDidILikeTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        let largeImagesDirURL = FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY)
        FileStorage.createDirectoryIfNeeded(largeImagesDirURL)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private class Test: Recommendations {
        var dates: [Date] {
            return []
        }
    }
    
    let file1 = "tmp1.dat"
    let file2 = "tmp2.dat"

    func testFileCreationDate() {
        let filePath = FileStorage.path(toItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY) + "/" + file1
        try? FileManager.default.removeItem(atPath: filePath)
        guard let str = "Hello World".data(using: .utf8) else {
            XCTFail()
            return
        }
        guard FileManager.default.createFile(atPath: filePath, contents: str, attributes: nil) else {
            XCTFail()
            return
        }
        
        let t = Test()
        guard let _ = t.fileCreationDate(filePath: filePath) else {
            XCTFail()
            return
        }
    }
    
    func testDistinctDates() {
        let t = Test()

        let d0 = t.numberOfDistinctDates([])
        XCTAssert(d0 == 0)
        
        let d1 = t.numberOfDistinctDates([Date()])
        XCTAssert(d1 == 1)
        
        let d2a = t.numberOfDistinctDates([Date(), Date() + t.Kseconds + 1])
        XCTAssert(d2a == 2)
        
        let d2b = t.numberOfDistinctDates([Date() + t.Kseconds + 1, Date()])
        XCTAssert(d2b == 2)
        
        let d2c = t.numberOfDistinctDates([Date() + (t.Kseconds - 100), Date()])
        XCTAssert(d2c == 1)
        
        let d2d = t.numberOfDistinctDates([Date(), Date()])
        XCTAssert(d2d == 1)
        
        let d3a = t.numberOfDistinctDates([Date() + t.Kseconds + 1, Date() + t.Kseconds + 1, Date()])
        XCTAssert(d3a == 2)
        
        let d3b = t.numberOfDistinctDates([Date() + t.Kseconds*20, Date() + t.Kseconds + 1, Date()])
        XCTAssert(d3b == 3)
    }
    
    func makeImageObject(fileName: String) -> Image? {
        let imageObj = Image.newObject()
        
        let filePath = FileStorage.path(toItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY) + "/" + fileName
        try? FileManager.default.removeItem(atPath: filePath)

        guard let str = "Hello World".data(using: .utf8) else {
            XCTFail()
            return nil
        }
        
        guard FileManager.default.createFile(atPath: filePath, contents: str, attributes: nil) else {
            XCTFail()
            return nil
        }
        
        let url = URL(fileURLWithPath: filePath)
        imageObj.fileName = url.lastPathComponent
        
        XCTAssert(imageObj.dates.count == 1)
        
        return imageObj
    }
    
    func testDatesInCoreDataObjects() {
        guard let image1 = makeImageObject(fileName: file1) else {
            XCTFail()
            return
        }
        
        let location1 = Location.newObject()
        XCTAssert(location1.dates.count == 1)
        
        location1.addToImages(image1)
        XCTAssert(location1.dates.count == 2)
        
        let item1 = Item.newObject()
        XCTAssert(item1.dates.count == 1)

        let comment1 = Comment.newObject()
        XCTAssert(comment1.dates.count == 1)
        
        guard let image2 = makeImageObject(fileName: file2) else {
            XCTFail()
            return
        }
        
        comment1.addToImages(image2)
        XCTAssert(comment1.dates.count == 2)
        
        item1.addToComments(comment1)
        XCTAssert(item1.dates.count == 3)

        let place1 = Place.newObject()
        XCTAssert(place1.dates.count == 1)

        place1.addToLocations(location1)
        XCTAssert(place1.dates.count == 3)
        
        place1.addToItems(item1)
        XCTAssert(place1.dates.count == 6)
        
        XCTAssert(place1.numberOfDistinctDates(place1.dates) == 1)
    }
}
