//
//  UUIDCollisionAvoidanceTests.swift
//  UnitTests
//
//  Created by Christopher G Prince on 4/1/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import XCTest
@testable import WhatDidILike
import SMCoreLib

class UUIDCollisionAvoidanceTests: XCTestCase {
    override func setUp() {
        setupExportFolder()
    }

    override func tearDown() {
    }

    func testWithNoCollision() throws {
        let uuid = Foundation.UUID()
        XCTAssert(!(try Place.alreadyExists(uuid: uuid).exists()))
    }

    func testWithCollision() throws {
        let place1 = try Place.newObject()
        place1.name = "My Favorite Restaurant"
        
        guard let uuid = place1.uuid else {
            XCTFail()
            return
        }
        
        XCTAssert(try Place.alreadyExists(uuid: uuid).exists())

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
    }
    
    // "fake" UUID collision-- attempt to import a place that has been imported already.
    func testImportPlaceWhereImportedPlaceIsTheSameAsCoreDataPlace() throws {
        // 1) Create a new place.
        let place1 = try Place.newObject()
        place1.name = "My Favorite Restaurant"
        
        guard let place1UUID = place1.uuid else {
            XCTFail()
            return
        }
        
        // 2) Export that place.
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        try placeExporter.export(place: place1)

        // 3) Import the place. We have *not* removed the prior place. Therefore, this attempts to import a place with the same uuid as an existing place.
        let placeExportDirectory = place1.createDirectoryName(in: Self.exportURL)
        
        XCTAssert(try Place.alreadyExists(uuid: place1UUID).exists())
        
        let place2 = try Place.import(from: placeExportDirectory, in: Self.exportURL)
        
        // 4) The place import should return nil because the place we were attempting to import has both the same uuid and the same creation date.
        XCTAssert(place2 == nil)
        
        // 5) Cleanup.
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
    }
    
    // "true" UUID collision
    func testImportPlaceWhereImportedPlaceIsHasSameUUIDButDifferentCreationDate() throws {
        // 1) Create a new place.
        let place1 = try Place.newObject()
        place1.name = "My Favorite Restaurant"
        
        guard let place1UUID = place1.uuid else {
            XCTFail()
            return
        }
        
        // 2) Export that place.
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        try placeExporter.export(place: place1)

        // 3) Import the place. We have *not* removed the prior place. Therefore, this attempts to import a place with the same uuid as an existing place.
        let placeExportDirectory = place1.createDirectoryName(in: Self.exportURL)
        
        XCTAssert(try Place.alreadyExists(uuid: place1UUID).exists())
        
        // 4) Tweak the date of place1 to simulate, in the next step, an import where UUIDs match but creation dates differ.
        place1.creationDate = (Date() - 100) as NSDate
        
        // 5) The place import should *not* return nil because the place we were attempting to import has the same uuid and but different creation date.
        guard let place2 = try Place.import(from: placeExportDirectory, in: Self.exportURL) else {
            XCTFail()
            return
        }
        
        // 6) To resolve the UUID collision, the uuid of the new place should have been changed.
        XCTAssert(place2.uuid != place1UUID)
        
        // 7) Cleanup.
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
}
