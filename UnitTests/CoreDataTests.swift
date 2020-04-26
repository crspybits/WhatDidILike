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
        setupLargeImagesFolder()
        setupExportFolder()
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
        place.save()
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        let urls = try placeExporter.export(place: place)
        guard urls.count > 0 else {
            XCTFail()
            return
        }
        
        try placeExporter.updateAlreadyExported()
              
        let placeCategory = try PlaceCategory.newObject(withName: "Something")
        place.category = placeCategory
        place.lastExport = Date() + 20
        place.save()
        
        // Seems to be something interesting going on with the file system. I immediately check the file system for the exported place, I don't find it. Seems to need a delay.

        let places = try placeExporter.needExport()
        
        XCTAssert(places.count == 0)
        
        place.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(placeCategory)
    }
    
    func testToEnsureAddingPlaceToPlaceListDoesNotUpdateModificationDate() throws {
        removePlaces()
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        
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
        
        let urls1 = try placeExporter.export(place: place1)
        guard urls1.count > 0 else {
            XCTFail()
            return
        }
                
        let place2 = try Place.newObject()
        place2.save()
        
        let urls2 = try placeExporter.export(place: place2)
        guard urls2.count > 0 else {
            XCTFail()
            return
        }
        
        try placeExporter.updateAlreadyExported()
        
        // This is the line of interest. This actually updates the `places` relation of the place category. And we're testing to ensure the modificationDate of the place category doesn't change as a result.
        place2.category = placeCategory1

        // Establish this place also as not needing export.
        place2.lastExport = Date()
         
        place2.save()
        
        let places2 = try placeExporter.needExport()
        guard places2.count == 0 else {
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
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        
        let place1 = try Place.newObject()
        place1.generalDescription = "Foo"
        place1.name = "Bar"
        place1.addToLists(placeList1)
        
        // Establish this place as not needing export.
        place1.lastExport = Date()
        place1.save()
        
        // It needs actual export too-- or `placeNeedsExporting` returns true.
        try placeExporter.export(place: place1)
        
        let place2 = try Place.newObject()
        place2.save()
        
        // Similarly, place2 needs actual export too-- or `placeNeedsExporting` returns true.
        try placeExporter.export(place: place2)
        
        // This the line of interest. This actually updates the `places` relation of the place list. And we're testing to ensure the modificationDate of the place list doesn't change as a result.
        place2.addToLists(placeList1)

        // Establish this place as not needing export.
        place2.lastExport = Date()
         
        place2.save()
        
        try placeExporter.updateAlreadyExported()
        
        let places2 = try placeExporter.needExport()
        
        guard places2.count == 0 else {
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
    
    func testFetchAllImageObjectsWithOneResultingImage() throws {
        let image = Image.newObject()
        let uuid: String = try Image.realUUID()
        image.uuid = uuid
        
        guard let images = try Image.fetchAllObjects(withUUID: uuid) else {
            XCTFail()
            return
        }
        
        XCTAssert(images.count == 1)
    }
    
    func testFetchAllImageObjectsWithTwoResultingImages() throws {
        let image1 = Image.newObject()
        let uuid1: String = try Image.realUUID()
        image1.uuid = uuid1
        
        // Simulate a UUID collision-- manually give a second image the same uuid
        let image2 = Image.newObject()
        image2.uuid = uuid1
        
        guard let images = try Image.fetchAllObjects(withUUID: uuid1) else {
            XCTFail()
            return
        }
        
        XCTAssert(images.count == 2)
    }
    
    func testCountNumberOfPlaces() throws {
        removePlaces()
        XCTAssert(try Place.numberOfObjects() == 0)
        
        _ = try Place.newObject()
        XCTAssert(try Place.numberOfObjects() == 1)
        removePlaces()
    }
    
    // Test both parameter settings.
    func testImageRemovalForPlace() throws {
        removePlaces()
        var uuid: String?
        
        // No image tests
        let t1 = {
            uuid = nil
            let place = try Place.newObject()
            let location = try Location.newObject()
            place.addToLocations(location)
            location.remove(uuidOfPlaceRemoved: &uuid)
            XCTAssert(uuid != nil)
        }
        try t1()

        let t2 = {
            uuid = nil
            let place = try Place.newObject()
            let location = try Location.newObject()
            place.addToLocations(location)
            location.remove(uuidOfPlaceRemoved: &uuid, removeImages: false)
            XCTAssert(uuid != nil)
        }
        try t2()
        
        // With image tests
        
        let t3 = {
            uuid = nil
            let place = try Place.newObject()
            let location = try Location.newObject()
            place.addToLocations(location)

            guard let (image, filePath) = try self.makeExampleImage() else {
                XCTFail()
                return
            }
            
            location.addToImages(image)
            location.remove(uuidOfPlaceRemoved: &uuid)
            
            XCTAssert(!FileManager.default.fileExists(atPath: filePath.path))
            XCTAssert(uuid != nil)
        }
        try t3()
        
        let t4 = {
            uuid = nil
            let place = try Place.newObject()
            let location = try Location.newObject()
            place.addToLocations(location)

            guard let (image, filePath) = try self.makeExampleImage() else {
                XCTFail()
                return
            }
            
            location.addToImages(image)
            location.remove(uuidOfPlaceRemoved: &uuid, removeImages: false)
            
            XCTAssert(FileManager.default.fileExists(atPath: filePath.path))
            XCTAssert(uuid != nil)
        }
        try t4()
    }
    
    func testImageRemovalForComment() throws {
        // No image tests
        let comment1 = try Comment.newObject()
        comment1.remove()
            
        let comment2 = try Comment.newObject()
        comment2.remove(removeImages: false)
        
        // With image tests
        
        // First: Image deletion
        let name = "example"
        let ext = "jpeg"

        let bundle = Bundle(for: Self.self)
        guard let bundleImageURL = bundle.url(forResource: name, withExtension: ext) else {
            XCTFail()
            return
        }
        
        let fileName = Image.createFileName(usingNewImageFileUUID: try Image.realUUID())
        let filePath = URL(fileURLWithPath: Image.filePath(for: fileName))
        try FileManager.default.copyItem(at: bundleImageURL, to: filePath)
        XCTAssert(FileManager.default.fileExists(atPath: filePath.path))

        let comment3 = try Comment.newObject()
        
        let image1 = Image.newObject()
        image1.fileName = fileName
        comment3.addToImages(image1)
        // Should remove image too.
        comment3.remove()
        XCTAssert(!FileManager.default.fileExists(atPath: filePath.path))
        
        // Second: Without image deletion
        let fileName2 = Image.createFileName(usingNewImageFileUUID: try Image.realUUID())
        let filePath2 = URL(fileURLWithPath: Image.filePath(for: fileName2))
        try FileManager.default.copyItem(at: bundleImageURL, to: filePath2)
        XCTAssert(FileManager.default.fileExists(atPath: filePath2.path))

        let comment4 = try Comment.newObject()
        
        let image2 = Image.newObject()
        image2.fileName = fileName2
        comment4.addToImages(image2)
        // Should *not* remove image too.
        comment4.remove(removeImages: false)
        XCTAssert(FileManager.default.fileExists(atPath: filePath2.path))
    }
    
    private func makeExampleImage() throws -> (Image, filePath: URL)? {
        let name = "example"
        let ext = "jpeg"

        let bundle = Bundle(for: Self.self)
        guard let bundleImageURL = bundle.url(forResource: name, withExtension: ext) else {
            XCTFail()
            return nil
        }
        
        let fileName = Image.createFileName(usingNewImageFileUUID: try Image.realUUID())
        let filePath = URL(fileURLWithPath: Image.filePath(for: fileName))
        try FileManager.default.copyItem(at: bundleImageURL, to: filePath)
        XCTAssert(FileManager.default.fileExists(atPath: filePath.path))
        
        let image = Image.newObject()
        image.fileName = fileName
        
        return (image, filePath)
    }
    
    func testImageRemovalForItem() throws {
        // No image tests
        let t1 = {
            let item = try Item.newObject()
            let comment = try Comment.newObject()
            item.addToComments(comment)
            item.remove()
        }
        try t1()
        
        let t2 = {
            let item = try Item.newObject()
            let comment = try Comment.newObject()
            item.addToComments(comment)
            item.remove(removeImages: false)
        }
        try t2()
        
        // With image tests
        
        // First, with image deletion
        let t3 = {
            let item = try Item.newObject()

            guard let (image, filePath) = try self.makeExampleImage() else {
                XCTFail()
                return
            }

            let comment = try Comment.newObject()
            item.addToComments(comment)
            comment.addToImages(image)
            
            // Should remove image too.
            item.remove()
            
            XCTAssert(!FileManager.default.fileExists(atPath: filePath.path))
        }
        try t3()
        
        // Second, with image deletion
        let t4 = {
            let item = try Item.newObject()

            guard let (image, filePath) = try self.makeExampleImage() else {
                XCTFail()
                return
            }
            
            let comment = try Comment.newObject()
            item.addToComments(comment)
            comment.addToImages(image)
            
            // Should *not* remove image too.
            item.remove(removeImages: false)
            
            XCTAssert(FileManager.default.fileExists(atPath: filePath.path))
        }
        try t4()
    }
    
    func testImageRemovalForLocation() throws {
        removePlaces()
        var uuid: String?
        
        // No image tests
        let t1 = {
            let location = try Location.newObject()
            location.remove(uuidOfPlaceRemoved: &uuid)
        }
        try t1()
         
        let t2 = {
            let location = try Location.newObject()
            location.remove(uuidOfPlaceRemoved: &uuid, removeImages: false)
        }
        try t2()
        
        // With image tests
        
        let t3 = {
            let location = try Location.newObject()

            guard let (image, filePath) = try self.makeExampleImage() else {
                XCTFail()
                return
            }
            
            location.addToImages(image)
            location.remove(uuidOfPlaceRemoved: &uuid)
            
            XCTAssert(!FileManager.default.fileExists(atPath: filePath.path))
        }
        try t3()
        
        let t4 = {
            let location = try Location.newObject()

            guard let (image, filePath) = try self.makeExampleImage() else {
                XCTFail()
                return
            }
            
            location.addToImages(image)
            location.remove(uuidOfPlaceRemoved: &uuid, removeImages: false)
            
            XCTAssert(FileManager.default.fileExists(atPath: filePath.path))
        }
        try t4()
    }
    
    func testThatRemovingBothLocationsForAPlaceAlsoRemovesPlace() throws {
        let place = try Place.newObject()
        let location1 = try Location.newObject()
        let location2 = try Location.newObject()
        place.addToLocations(location1)
        place.addToLocations(location2)

        guard var locations = place.locations as? Set<Location>,
            locations.count == 2 else {
            XCTFail()
            return
        }
            
        var uuidOfPlaceRemoved: String?
        while locations.count > 0 {
            let location = locations.removeFirst()
            location.remove(uuidOfPlaceRemoved: &uuidOfPlaceRemoved, removeImages: false)
        }
        
        XCTAssert(uuidOfPlaceRemoved != nil)
    }
    
    func testThatIgnoredFieldsDoNotUpdateModificationDate() throws {
        /*
        Place.suggestionField,
        Location.TRY_AGAIN_KEY,
        Location.DISTANCE_KEY,
        Location.internalRatingField
         */
         
        let originalDate = (Date() - 100) as NSDate
         
        let place = try Place.newObject()
        // So I can detect a change
        place.modificationDate = originalDate
        place.save()
        
        place.suggestion = 1
        place.save()
        
        XCTAssert(place.modificationDate == originalDate)
        
        let location = try Location.newObject()
        // So I can detect a change
        location.modificationDate = originalDate
        location.save()
        
        location.internalGoBack = 1
        location.save()
        XCTAssert(location.modificationDate == originalDate)

        location.internalDistance = 1
        location.save()
        XCTAssert(location.modificationDate == originalDate)
        
        location.internalRating = 1
        location.save()
        XCTAssert(location.modificationDate == originalDate)
    }
}
