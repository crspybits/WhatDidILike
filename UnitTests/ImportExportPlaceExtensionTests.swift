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
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            } catch {
                XCTFail()
            }
        }
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
        
        let directoryName = place.createDirectoryName(in: Self.exportURL)
                
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
        
        let directoryName = place.createDirectoryName(in: Self.exportURL)
                
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

        let newFile = URL(fileURLWithPath: newDirectory.path + "/" + "tmp.txt", relativeTo: nil)

        let contents = "Hello World!".data(using: .utf8)!
        
        FileManager.default.createFile(atPath: newFile.path, contents: contents, attributes: nil)
        
        try place.reCreateDirectory(placeExportDirectory: Self.exportURL)
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
    
    func testNeedExportWithPlacesButNoneNeedingExport() throws {
        removePlaces()

        let place = try Place.newObject()
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
    
    func testNeedExportWithPlacesWithOneWithNilLastExport() throws {
        removePlaces()

        let place = try Place.newObject()
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
        XCTAssert(exportPlaces[0].uuid == place.uuid)
    }
    
    func testNeedExportWithPlacesWithOneMoreRecentlyChanged() throws {
        removePlaces()

        let place = try Place.newObject()
        
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
        
        // Because if the lastExport and another field (e.g., name, below) are changed together, the modificationDate doesn't get updated.
        place.save()
        
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
        
        XCTAssert(exportPlaces2[0].uuid == place.uuid)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
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
