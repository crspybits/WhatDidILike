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

    func testToEnsureLastExportFieldNameIsCorrect() throws {
        let place = try Place.newObject()
        place.lastExport = Date()
        XCTAssert(place.value(forKey: Place.lastExportField) != nil)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
    }
    
    func testToEnsureModificationDateFieldNameIsCorrect() throws {
        let place = try Place.newObject()
        place.save()
        XCTAssert(place.value(forKey: BaseObject.modificationDateField) != nil)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
    }
    
    func testToEnsureLastExportFieldChangeWithOtherChangesIsNotExportable() throws {
        removePlaces()
        
        let place = try Place.newObject()
        place.name = "Foo"
        place.lastExport = Date()
        place.save()
        
        guard let (places, _) = Place.needExport() else {
            XCTFail()
            return
        }
        
        XCTAssert(places.count == 0)
    }
    
    func testToEnsureAddingPlaceToPlaceListDoesNotUpdateModificationDate() throws {
        removePlaces()
        
        let placeCategoryName = "Foo Biz"
        guard let placeCategory1 = try? PlaceCategory.newObject(withName: placeCategoryName) else {
            XCTFail()
            return
        }
        
        let place1 = try Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        place1.category = placeCategory1
        
        // Establish this place as not needing export.
        place1.lastExport = Date()
        
        place1.save()
        
        guard let (places, _) = Place.needExport(), places.count == 0 else {
            XCTFail()
            return
        }
        
        let place2 = try Place.newObject()
        
        // This the line of interest. This actually updates the `places` relation of the place category. And we're testing to ensure the modificationDate of the place category doesn't change as a result.
        place2.category = placeCategory1

        // Establish this place also as not needing export.
        place2.lastExport = Date()
         
        place2.save()
        
        guard let (places2, _) = Place.needExport(), places2.count == 0 else {
            XCTFail()
            return
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testToEnsureAddingPlaceToPlaceCategoryDoesNotUpdateModificationDate() throws {
        removePlaces()
        
        let placeListName = "Foo Biz"
        guard let placeList1 = try? PlaceList.newObject(withName: placeListName) else {
            XCTFail()
            return
        }
        
        let place1 = try Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        place1.addToLists(placeList1)
        
        // Establish this place as not needing export.
        place1.lastExport = Date()
        
        place1.save()
        
        guard let (places, _) = Place.needExport(), places.count == 0 else {
            XCTFail()
            return
        }
        
        let place2 = try Place.newObject()
        
        // This the line of interest. This actually updates the `places` relation of the place list. And we're testing to ensure the modificationDate of the place list doesn't change as a result.
        place2.addToLists(placeList1)

        // Establish this place also as not needing export.
        place2.lastExport = Date()
         
        place2.save()
        
        guard let (places2, _) = Place.needExport(), places2.count == 0 else {
            XCTFail()
            return
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeList1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testLastExportReset() throws {
        let place1 = try Place.newObject()
        place1.lastExport = Date()
        
        let place2 = try Place.newObject()
        place2.lastExport = Date()
        
        place1.save()
        
        Place.resetLastExports()
        
        XCTAssert(place1.lastExport == nil)
        XCTAssert(place2.lastExport == nil)

        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}
