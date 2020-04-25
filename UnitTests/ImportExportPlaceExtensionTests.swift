//
//  ImportExportPlaceExtensionTests.swift
//  UnitTests
//
//  Created by Christopher G Prince on 3/20/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import XCTest
@testable import WhatDidILike
import SMCoreLib

extension XCTestCase {
    static let exportFolder = "Export" // within Documents
    static var exportURL: URL!
    
    func setupExportFolder() {
        guard let url = FileStorage.url(ofItem: Self.exportFolder) else {
            XCTFail()
            return
        }
        
        Self.exportURL = url
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        } catch {
            XCTFail()
        }
    }
    
    func setupLargeImagesFolder() {
        try? FileManager.default.createDirectory(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY), withIntermediateDirectories: false, attributes: nil)
    }
}

class ImportExportPlaceExtensionTests: XCTestCase {
    override func setUp() {
        setupExportFolder()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateDirectoryNameWithNoPlaceName() throws {
        let place = try Place.newObject()
        
        let directoryName = place.exportDirectoryName(in: Self.exportURL)
                
        guard !FileManager.default.fileExists(atPath: directoryName.path) else {
            XCTFail()
            return
        }
        
        do {
            try FileManager.default.createDirectory(at: directoryName, withIntermediateDirectories: false, attributes: nil)
        } catch {
            XCTFail()
        }
    }
    
    func testCreateDirectoryNameWithPlaceName() throws {
        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let directoryName = place.exportDirectoryName(in: Self.exportURL)
                
        guard !FileManager.default.fileExists(atPath: directoryName.path) else {
            XCTFail()
            return
        }
        
        do {
            try FileManager.default.createDirectory(at: directoryName, withIntermediateDirectories: false, attributes: nil)
        } catch {
            XCTFail()
        }
    }
    
    func testCreateDirectoryWithNoPlaceName() throws {
        let place = try Place.newObject()
        
        do {
            let _ = try place.createNewDirectory(in: Self.exportURL)
        } catch {
            XCTFail()
        }
    }
    
    func testCreateDirectoryWithPlaceName() throws {
        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"

        do {
            let _ = try place.createNewDirectory(in: Self.exportURL)
        } catch {
            XCTFail()
        }
    }
    
    func testReCreateDirectoryWithContents() throws {
        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"

        let newDirectory: URL
        do {
            newDirectory = try place.createNewDirectory(in: Self.exportURL)
        } catch {
            XCTFail()
            return
        }
        
        // newFile.path igores the relativeTo part. Odd.
        // let newFile = URL(fileURLWithPath: "tmp.txt", relativeTo: newDirectory)

        let newFile = newDirectory.appendingPathComponent("tmp.txt")

        let contents = "Hello World!".data(using: .utf8)!
        
        FileManager.default.createFile(atPath: newFile.path, contents: contents, attributes: nil)
        
        try place.reCreateDirectory(placeExportDirectory: Self.exportURL)
    }
    
    func testNeedExportWithNoPlaces() throws {
        removePlaces()
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, accessor: .securityScoped)
        let exportPlaces = try placeExporter.needExport()
        
        XCTAssert(exportPlaces.count == 0)
    }
    
    func testNeedExportWithPlacesAndOneNeedingExport() throws {
        removePlaces()

        let place = try Place.newObject()
        place.save()
        
        place.lastExport = Date()
                
        // Make sure `willSave` doesn't update the modification date by just changing lastExport.
        place.save()
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        let exportPlaces = try placeExporter.needExport()
        
        // This is 1-- because the place hasn't yet been exported. No export folder.
        XCTAssert(exportPlaces.count == 1)
                
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
    }
    
    func testNeedExportWithPlacesWithOneWithNilLastExport() throws {
        removePlaces()

        let place = try Place.newObject()
        // place.lastExport will be nil
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        let exportPlaces = try placeExporter.needExport()

        guard exportPlaces.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(exportPlaces[0].uuid == place.uuid)
    }
    
    func testCreateLargeImagesDirectoryIfNeededWithFolderAbsent() throws {
        try? FileManager.default.removeItem(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY))
        
        try Place.createLargeImagesDirectoryIfNeeded()
        
        if !FileManager.default.fileExists(atPath: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY)!.path) {
            XCTFail()
            return
        }
    }
    
    func testCreateLargeImagesDirectoryIfNeededWithFolderPresent() throws {
        try? FileManager.default.removeItem(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY))
        
        try Place.createLargeImagesDirectoryIfNeeded()
        
        if !FileManager.default.fileExists(atPath: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY)!.path) {
            XCTFail()
            return
        }
        
        // The actual test call-- folder present already.
        try Place.createLargeImagesDirectoryIfNeeded()
    }
    
    func testGetUUIDFrom() throws {
        let goodURL = URL(fileURLWithPath: "/Foobar/Afra_C8F8D06D-A45F-4431-94B2-FE6C34D91118")
        let uuid = try Place.getUUIDFrom(url: goodURL)
        XCTAssert(uuid == "C8F8D06D-A45F-4431-94B2-FE6C34D91118")
        
        let badURL = URL(fileURLWithPath: "/Foobar/Afra_C8F8D06D-A45F-4431-94B2-")
        do {
            _ = try Place.getUUIDFrom(url: badURL)
        } catch {
            return
        }
        
        XCTFail()
    }
    
    func testPeekAtPlace() throws {
        removePlaces()
        
        // 1) Export a place
        let place = try Place.newObject()
        place.save()
        
        XCTAssert(place.creationDate != nil)
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        let urls = try placeExporter.export(place: place)
        
        guard urls.count == 1 else {
            XCTFail()
            return
        }
    
        // 2) Peek at it.
        
        // Remove the place.json from the end of the URL
        let placeExportURL = urls[0].deletingLastPathComponent()

        let (_, partialPlace) = try Place.peek(with: placeExportURL, in: Self.exportURL)
        
        // 3) Make sure the peek reflects the exported place.
        XCTAssert(partialPlace.creationDate == place.creationDate)
        XCTAssert(partialPlace.uuid == place.uuid)
        
        // 4) Cleanup
        place.remove()
        place.save()
    }
    
    func createImageWithUUIDName() throws -> Image? {
        let name = "example"
        let ext = "jpeg"

        let bundle = Bundle(for: Self.self)
        guard let bundleURL = bundle.url(forResource: name, withExtension: ext) else {
            XCTFail()
            return nil
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
                return nil
            }
        }
        
        let image = Image.newObject()
        image.fileName = imageFileNameWithUUID
        image.uuid = imageUUID
        
        return image
    }
    
    func testFailureCopyingImageFromExportToAppWhenDoingPlaceImport() throws {
        // Remove places and locations so we can be confident of results after the test when testing for number of places and locations.
        removePlaces()
        if let locations = Location.fetchAllObjects() {
            var unusedUuid:String?
            for location in locations {
                location.remove(uuidOfPlaceRemoved: &unusedUuid)
            }
        }
        
        // A) Prepare for the import-- create a place and export it.
        let place = try Place.newObject()
        place.name = "Fooby"
        let location = try Location.newObject()
        place.addToLocations(location)
        
        // Give the place/location a couple of images.
        guard let image1 = try createImageWithUUIDName() else {
            XCTFail()
            return
        }
        
        guard let image2 = try createImageWithUUIDName() else {
            XCTFail()
            return
        }
        
        guard let image1UUID = image1.uuid,
            let image2UUID = image2.uuid else {
            XCTFail()
            return
        }
        
        guard let image2FileName = image2.fileName else {
            XCTFail()
            return
        }
        
        location.addToImages(image1)
        location.addToImages(image2)
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        let exportedURLs = try placeExporter.export(place: place)
        
        // urls: The .json file and the two images.
        guard exportedURLs.count == 3 else {
            XCTFail()
            return
        }

        // B) Interfere with the exported place so that an import of the place will fail.
        // Which one of the URL's is for the second image?
        
        var secondImageExportURL:URL!
        for url in exportedURLs {
            if url.path.contains(image2FileName) {
                secondImageExportURL = url
            }
        }
                
        XCTAssert(secondImageExportURL != nil)
        try FileManager.default.removeItem(at: secondImageExportURL)
        
        // C) Remove the place, location, and images from Core Data so we can do an import
        // This should remove all of the images and the place.
        var uuid: String?
        location.remove(uuidOfPlaceRemoved: &uuid)
        XCTAssert(uuid != nil)
        
        // D) Do the import, and expect a failure.
        let placeExportURL = exportedURLs[0].deletingLastPathComponent()

        do {
            try Place.import(from: placeExportURL, in: Self.exportURL)
        } catch {
            // Expect to be here.
            
            // E) Check for proper cleanup
            
            // There should be no place in Core Data with the given UUID after the failure.
            // And since we cleaned up, there should be no places at all.
            let places = Place.fetchAllObjects()
            XCTAssert(places?.count == 0)
            
            // There should be no locations related to that place remaining after that failure.
            let locations = Location.fetchAllObjects()
            XCTAssert(locations?.count == 0)
            
            // There should be no images in the app as a result of the partial copy.
            let image1 = try Image.fetchObject(withUUID: image1UUID)
            XCTAssert(image1 == nil)
            
            let image2 = try Image.fetchObject(withUUID: image2UUID)
            XCTAssert(image2 == nil)
            
            return
        }
        
        // Didn't get failure on import. Whoops.
        XCTFail()
    }
}

extension XCTestCase {
    func removePlaces() {
        if var places = Place.fetchAllObjects() {
            while !places.isEmpty {
                let place = places.remove(at: 0)
                CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
            }
        }
    }
}
