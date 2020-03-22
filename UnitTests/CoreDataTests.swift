//
//  CoreDataTests.swift
//  UnitTests
//
//  Created by Christopher G Prince on 3/21/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import XCTest
@testable import WhatDidILike
import SMCoreLib

class CoreDataTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testToEnsureLastExportFieldNameIsCorrect() {
        let place = Place.newObject()
        place.lastExport = Date()
        XCTAssert(place.value(forKey: Place.lastExportField) != nil)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
    }
    
    func testToEnsureModificationDateFieldNameIsCorrect() {
        let place = Place.newObject()
        place.save()
        XCTAssert(place.value(forKey: BaseObject.modificationDateField) != nil)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
    }
}
