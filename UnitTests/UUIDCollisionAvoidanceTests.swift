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
        let placeExportDirectory = place1.exportDirectoryName(in: Self.exportURL)
        
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
        let placeExportDirectory = place1.exportDirectoryName(in: Self.exportURL)
        
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
        
        // 7) And the export directory for the place ought to have been renamed based on the new UUID.
        XCTAssert(!FileManager.default.fileExists(atPath: placeExportDirectory.path))
        
        let newPlaceExportDirectory = place2.exportDirectoryName(in: Self.exportURL)
        XCTAssert(placeExportDirectory.path != newPlaceExportDirectory.path)
        XCTAssert(FileManager.default.fileExists(atPath: newPlaceExportDirectory.path))
        
        let newUUID = try Place.getUUIDFrom(url: newPlaceExportDirectory)
        XCTAssert(newUUID == place2.uuid)
        
        // 8) Cleanup.
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place1)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place2)
    }
    
    // Restore case: Image being restored has pre-v2.2 image naming. No possibility of UUID collision or other collision in this case.
    func testImageWithoutCollision_ImageHasNoUUID() {
        // Nothing more to do here. All places have uuid's. Images created pre-v2.2 will have the non-uuid naming. But, those won't be subject to collisions on import because (a) all image names will be unique because of the way they are created pre-export, and (b) we never re-import a place with same uuid and creationDate that already exists in Core Data.
    }
    
    // Expect no image file name change
    func testImageWithoutCollision_ImageHasUUIDAndNoExistingOtherImageFileWithSameUUID() throws {
        // Phase 1: Export a place with image with UUID file naming.
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)

        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let name = "example"
        let ext = "jpeg"

        let bundle = Bundle(for: Self.self)
        guard let bundleURL = bundle.url(forResource: name, withExtension: ext) else {
            XCTFail()
            return
        }
        
        let imageUUID: String = try Image.realUUID()
        let imageFileNameWithUUID = Image.createFileName(usingNewImageFileUUID: imageUUID)
        
        let documentsImageURL = URL(fileURLWithPath: Image.filePath(for: imageFileNameWithUUID))
        
        if !FileManager.default.fileExists(atPath: documentsImageURL.path) {
            try? FileManager.default.createDirectory(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY), withIntermediateDirectories: false, attributes: nil)
            do {
                try FileManager.default.copyItem(at: bundleURL, to: documentsImageURL)
            } catch {
                XCTFail()
                return
            }
        }
        
        let image = Image.newObject()
        image.fileName = imageFileNameWithUUID
        image.uuid = imageUUID
        
        let location = try Location.newObject()
        location.addToImages(image)
        place.addToLocations(location)
        
        let urls:[URL]
        do {
            urls = try placeExporter.export(place: place)
        } catch {
            XCTFail()
            return
        }
        
        guard urls.count == 2 else {
            XCTFail()
            return
        }
        
        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else {
                XCTFail()
                return
            }
        }
        
        let placeExportDirectory = urls[0].deletingLastPathComponent()
        
        // Phase 2. So, we have one Place. I want to demonstrate the use case of importing another place, and not getting a collision of a uuid-named image. This could occur when (1) places had been exported post-v2.2, (2) the app was deleted, (3) the app reinstalled, (4) places were created, (5) and then places were imported.
        
        // This is to simulate app deletion. The exported Place will remain.
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(image)
        try FileManager.default.removeItem(at: documentsImageURL)
        
        // Affirm that the exported Place remains.
        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else {
                XCTFail()
                return
            }
        }
        
        // Simulate app re-install, and creation of a place.
        let place2 = try Place.newObject()
        place2.name = "My Favorite Restaurant"
        
        let imageUUID2: String = try Image.realUUID()
        let imageFileNameWithUUID2 = Image.createFileName(usingNewImageFileUUID: imageUUID2)
        
        let documentsImageURL2 = URL(fileURLWithPath: Image.filePath(for: imageFileNameWithUUID2))
        
        // This is relying on the typical low probability of collisions with UUID's.
        try FileManager.default.copyItem(at: bundleURL, to: documentsImageURL2)

        let image2 = Image.newObject()
        image2.fileName = imageFileNameWithUUID2
        image2.uuid = imageUUID2
        
        let location2 = try Location.newObject()
        location2.addToImages(image2)
        place2.addToLocations(location2)
        
        // Finally, simulate a place import
        guard let importedPlace = try Place.import(from: placeExportDirectory, in: Self.exportURL) else {
            XCTFail()
            return
        }
        
        // Get the image object from the imported Core Data place
        guard let importedLocations = importedPlace.locations as? Set<Location>,
            importedLocations.count == 1,
            let firstImportedLocation = importedLocations.first,
            let importedImages = firstImportedLocation.images?.array as? [Image],
            importedImages.count == 1 else {
            XCTFail()
            return
        }

        // Make sure the place import didn't change the image UUID or filename.
        XCTAssert(importedImages[0].fileName == imageFileNameWithUUID)
        XCTAssert(importedImages[0].uuid == imageUUID)
    }
    
    // Use case: (1) places had been exported post-v2.2, (2) the app was deleted, (3) the app reinstalled, (4) places were created, (5) and then places were imported. To get an image name collision we need the same uuid for an image from (1) and (4).
    // Expect image file name to be changed before being written into the /Documents folder from the export folder and expect the Image object fileName and uuid attributes to change as part of import.
    func testImageWithCollision_ImageHasUUIDAndExistingOtherImageFileWithSameUUID() throws {
        // Export a place with image with UUID file naming.
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)

        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let name = "example"
        let ext = "jpeg"

        let bundle = Bundle(for: Self.self)
        guard let bundleURL = bundle.url(forResource: name, withExtension: ext) else {
            XCTFail()
            return
        }
        
        let imageUUID: String = try Image.realUUID()
        let imageFileNameWithUUID = Image.createFileName(usingNewImageFileUUID: imageUUID)
        
        let documentsImageURL = URL(fileURLWithPath: Image.filePath(for: imageFileNameWithUUID))
        
        if !FileManager.default.fileExists(atPath: documentsImageURL.path) {
            try? FileManager.default.createDirectory(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY), withIntermediateDirectories: false, attributes: nil)
            do {
                try FileManager.default.copyItem(at: bundleURL, to: documentsImageURL)
            } catch {
                XCTFail()
                return
            }
        }
        
        let image = Image.newObject()
        image.fileName = imageFileNameWithUUID
        image.uuid = imageUUID
        
        let location = try Location.newObject()
        location.addToImages(image)
        place.addToLocations(location)
        
        let urls:[URL]
        do {
            urls = try placeExporter.export(place: place)
        } catch {
            XCTFail()
            return
        }
        
        guard urls.count == 2 else {
            XCTFail()
            return
        }
        
        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else {
                XCTFail()
                return
            }
        }
        
        let placeExportDirectory = urls[0].deletingLastPathComponent()
        
        // Simulate app deletion. The exported Place will remain.
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(location)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(image)
        try FileManager.default.removeItem(at: documentsImageURL)
        
        // Simulate app re-install, and creation of a place. This is where the image collision occurs.
        let place2 = try Place.newObject()
        place2.name = "My Favorite Restaurant"
        
        let documentsImageURL2 = URL(fileURLWithPath: Image.filePath(for: imageFileNameWithUUID))
        
        // This is relying on the typical low probability of collisions with UUID's.
        try FileManager.default.copyItem(at: bundleURL, to: documentsImageURL2)

        let image2 = Image.newObject()
        // Using colliding UUID [**]-- this UUID is the same as in the image now in the export folder.
        image2.fileName = imageFileNameWithUUID
        image2.uuid = imageUUID
        
        let location2 = try Location.newObject()
        location2.addToImages(image2)
        place2.addToLocations(location2)
        
        // Finally, simulate a place import
        guard let importedPlace = try Place.import(from: placeExportDirectory, in: Self.exportURL) else {
            XCTFail()
            return
        }
        
        // Get the image object from the imported Core Data place
        guard let importedLocations = importedPlace.locations as? Set<Location>,
            importedLocations.count == 1,
            let firstImportedLocation = importedLocations.first,
            let importedImages = firstImportedLocation.images?.array as? [Image],
            importedImages.count == 1 else {
            XCTFail()
            return
        }

        // Make sure the place import *did* change the image UUID and filename. Notice this is the critical assertion since the same (see [**] above) Image uuid was used as one existing in Core Data already.
        XCTAssert(importedImages[0].fileName != imageFileNameWithUUID)
        XCTAssert(importedImages[0].uuid != imageUUID)
        
        XCTAssert(FileManager.default.fileExists(atPath: importedImages[0].filePath))
    }
}
