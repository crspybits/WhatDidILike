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

class ImportExportPlaceExtensionTests: XCTestCase {
    let exportFolder = "Export" // within Documents
    var exportURL: URL!
    
    override func setUp() {
        guard let url = FileStorage.url(ofItem: exportFolder) else {
            XCTFail()
            return
        }
        
        exportURL = url
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            } catch {
                XCTFail()
            }
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateDirectoryNameWithNoPlaceName() {
        let place = Place.newObject()
        
        let directoryName = place.createDirectoryName(in: exportURL)
                
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
    
    func testCreateDirectoryNameWithPlaceName() {
        let place = Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let directoryName = place.createDirectoryName(in: exportURL)
                
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
    
    func testCreateDirectoryWithNoPlaceName() {
        let place = Place.newObject()
        
        do {
            let _ = try place.createDirectory(in: exportURL)
        } catch {
            XCTFail()
        }
    }
    
    func testCreateDirectoryWithPlaceName() {
        let place = Place.newObject()
        place.name = "My Favorite Restaurant"

        do {
            let _ = try place.createDirectory(in: exportURL)
        } catch {
            XCTFail()
        }
    }
    
    func testReCreateDirectoryWithContents() {
        let place = Place.newObject()
        place.name = "My Favorite Restaurant"

        let newDirectory: URL
        do {
            newDirectory = try place.createDirectory(in: exportURL)
        } catch {
            XCTFail()
            return
        }
        
        // newFile.path igores the relativeTo part. Odd.
        // let newFile = URL(fileURLWithPath: "tmp.txt", relativeTo: newDirectory)

        let newFile = URL(fileURLWithPath: newDirectory.path + "/" + "tmp.txt", relativeTo: nil)

        let contents = "Hello World!".data(using: .utf8)!
        
        FileManager.default.createFile(atPath: newFile.path, contents: contents, attributes: nil)
        
        do {
            _ = try place.createDirectory(in: exportURL)
        } catch {
            XCTFail()
            return
        }
    }
    
    @discardableResult
    func exportWithNoImages() -> Place? {
        let place = Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let time1 = Date()
        
        let urls:[URL]
        do {
            urls = try place.export(to: exportURL)
        } catch {
            XCTFail()
            return nil
        }
        
        let time2 = Date()

        guard let lastExportDate = place.lastExport else {
            XCTFail()
            return nil
        }
        
        XCTAssert(lastExportDate >= time1 && lastExportDate <= time2)
        
        guard urls.count == 1 else {
            XCTFail()
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: urls[0].path) else {
            XCTFail()
            return nil
        }
        
        return place
    }
    
    func testExportWithNoImages() {
        exportWithNoImages()
    }
    
    func exportWithOneImage() {
        let place = Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let name = "example"
        let ext = "jpeg"
        let imageInTestBundle = "\(name).\(ext)"

        let bundle = Bundle(for: ImportExportPlaceExtensionTests.self)
        guard let bundleURL = bundle.url(forResource: name, withExtension: ext) else {
            XCTFail()
            return
        }
        
        let documentsImageURL = URL(fileURLWithPath: Image.filePath(for: imageInTestBundle))
        
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
        image.fileName = imageInTestBundle
        
        let location = Location.newObject()
        location.addToImages(image)
        place.addToLocations(location)
        
        let urls:[URL]
        do {
            urls = try place.export(to: exportURL)
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
    }
    
    func testExportWithOneImage() {
        exportWithOneImage()
    }
    
    @discardableResult
    func exportWithTwoImages() -> Place? {
        let place = Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let name = "example"
        let name2 = "example2"
        let ext = "jpeg"
        let imageInTestBundle = "\(name).\(ext)"
        let imageInTestBundle2 = "\(name2).\(ext)"

        let bundle = Bundle(for: ImportExportPlaceExtensionTests.self)
        guard let bundleURL = bundle.url(forResource: name, withExtension: ext) else {
            XCTFail()
            return nil
        }
        
        guard let bundleURL2 = bundle.url(forResource: name2, withExtension: ext) else {
            XCTFail()
            return nil
        }
        
        let documentsImageURL = URL(fileURLWithPath: Image.filePath(for: imageInTestBundle))
        let documentsImageURL2 = URL(fileURLWithPath: Image.filePath(for: imageInTestBundle2))

        if !FileManager.default.fileExists(atPath: documentsImageURL.path) {
            try? FileManager.default.createDirectory(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY), withIntermediateDirectories: false, attributes: nil)
            do {
                try FileManager.default.copyItem(at: bundleURL, to: documentsImageURL)
            } catch {
                XCTFail()
                return nil
            }
        }
        
        if !FileManager.default.fileExists(atPath: documentsImageURL2.path) {
            try? FileManager.default.createDirectory(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY), withIntermediateDirectories: false, attributes: nil)
            do {
                try FileManager.default.copyItem(at: bundleURL2, to: documentsImageURL2)
            } catch {
                XCTFail()
                return nil
            }
        }
        
        let location = Location.newObject()
        place.addToLocations(location)
        
        let image = Image.newObject()
        image.fileName = imageInTestBundle
        location.addToImages(image)

        let image2 = Image.newObject()
        image2.fileName = imageInTestBundle2
        location.addToImages(image2)
        
        let urls:[URL]
        do {
            urls = try place.export(to: exportURL)
        } catch {
            XCTFail()
            return nil
        }
        
        guard urls.count == 3 else {
            XCTFail()
            return nil
        }
        
        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else {
                XCTFail()
                return nil
            }
        }
        
        return place
    }
    
    func testExportWithTwoImages() {
        exportWithTwoImages()
    }
    
    func testExportDirectories() {
        exportWithNoImages()
        
        let urls: [URL]
        do {
            urls = try Place.exportDirectories(in: exportURL)
        } catch {
            XCTFail()
            return
        }
        
        XCTAssert(urls.count > 0)
        
        for url in urls {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                XCTFail()
                return
            }
            
            XCTAssert(isDirectory.boolValue)
        }
    }
    
    func testImportWithNoImages() throws {
        guard let place = exportWithNoImages() else {
            XCTFail()
            return
        }
        
        guard let id = place.id as? Place.IdType else {
            XCTFail()
            return
        }
        
        let placeExportDirectory = place.createDirectoryName(in: exportURL)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
        
        guard try Place.fetchObject(withId: id) == nil else {
            XCTFail()
            return
        }
        
        let importedPlace = try Place.import(from: placeExportDirectory)
        
        XCTAssert(importedPlace != nil)
        
        guard try Place.fetchObject(withId: id) != nil else {
            XCTFail()
            return
        }
    }
        
    func testImportWithImages() throws {
        guard let place = exportWithTwoImages() else {
            XCTFail()
            return
        }
        
        let placeExportDirectory = place.createDirectoryName(in: exportURL)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)

        let importedPlace = try Place.import(from: placeExportDirectory)
        
        XCTAssert(importedPlace != nil)
        
        guard let locations = importedPlace?.locations as? Set<Location>,
            locations.count == 1 else {
            XCTFail()
            return
        }
        
        for location in locations {
            guard let images = location.images?.array as? [Image] else {
                XCTFail()
                return
            }
            
            XCTAssert(images.count == 2)
            
            for image in images {
                XCTAssert(image.fileName != nil)
                XCTAssert(FileManager.default.fileExists(atPath: image.filePath))
            }
        }
    }
    
    func removePlaces() {
        if var places = Place.fetchAllObjects() {
            while !places.isEmpty {
                let place = places.remove(at: 0)
                CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
            }
        }
    }
    
    func testNeedExportWithNoPlaces() {
        removePlaces()
        
        guard let (exportPlaces, totalNumber) = Place.needExport() else {
            XCTFail()
            return
        }
        
        XCTAssert(exportPlaces.count == 0)
        XCTAssert(totalNumber == 0)
    }
    
    func testNeedExportWithPlacesButNoneNeedingExport() {
        removePlaces()

        let place = Place.newObject()
        place.save()
        
        place.lastExport = Date()
                
        // Make sure `willSave` doesn't update the modification date by just changing lastExport.
        place.save()
        
        guard let (exportPlaces, totalNumber) = Place.needExport() else {
            XCTFail()
            return
        }
        
        XCTAssert(exportPlaces.count == 0)
        XCTAssert(totalNumber == 1)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
    }
    
    func testNeedExportWithPlacesWithOneWithNilLastExport() {
        removePlaces()

        let place = Place.newObject()
        // place.lastExport will be nil
        
        guard let (exportPlaces, totalNumber) = Place.needExport() else {
            XCTFail()
            return
        }

        guard exportPlaces.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(totalNumber == 1)
        XCTAssert(exportPlaces[0].id?.int32Value == place.id?.int32Value)
    }
    
    func testNeedExportWithPlacesWithOneMoreRecentlyChanged() {
        removePlaces()

        let place = Place.newObject()
        
        // Simulate an export
        place.lastExport = Date()
        
        guard let (exportPlaces, _) = Place.needExport() else {
            XCTFail()
            return
        }
        
        guard exportPlaces.count == 0 else {
            XCTFail()
            return
        }
        
        // Wait for some time to go by, so the modification date is different from the lastExport date.
        usleep(200)
        
        // This should make the place `dirty`-- needing export
        place.name = "foo"
        place.save() // Needed to get the modification date updated.
        
        guard let (exportPlaces2, _) = Place.needExport() else {
            XCTFail()
            return
        }
        
        guard exportPlaces2.count == 1 else {
            XCTFail()
            return
        }
        
        XCTAssert(exportPlaces2[0].id?.int32Value == place.id?.int32Value)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
    }
}
