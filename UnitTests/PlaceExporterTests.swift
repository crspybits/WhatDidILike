//
//  PlaceExporterTests.swift
//  UnitTests
//
//  Created by Christopher G Prince on 3/28/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import XCTest
@testable import WhatDidILike
import SMCoreLib

class PlaceExporterTests: XCTestCase {
    override func setUp() {
        setupExportFolder()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExportedPlaceThatHasNotBeenExported() throws {
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)

        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"
        place.save()
        
        let exportedPlace = try placeExporter.exportedPlace(place: place)
        XCTAssert(exportedPlace == nil)
    }
    
    func testExportedPlaceThatHasBeenExported() throws {
        removePlaces()
        
        guard let (place, _, placeExporter) = try exportWithNoImages() else {
            XCTFail()
            return
        }
        
        try placeExporter.updateAlreadyExported()
        
        let exportedPlace = try placeExporter.exportedPlace(place: place)
        XCTAssert(exportedPlace != nil)
        
        let places = try placeExporter.needExport()
        guard places.count == 0 else {
            XCTFail()
            return
        }
    }
    
    @discardableResult
    func exportWithNoImages(initializeREADME:Bool = true) throws -> (Place, URL, PlaceExporter)? {
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, initializeREADME: initializeREADME)
        
        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let time1 = Date()
        
        let urls:[URL]
        do {
            urls = try placeExporter.export(place: place)
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
        
        return (place, urls[0], placeExporter)
    }
    
    func testExportWithNoImages() throws {
        try exportWithNoImages()
    }
    
    func exportWithOneImage() throws {
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)

        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"
        
        let name = "example"
        let ext = "jpeg"
        let imageInTestBundle = "\(name).\(ext)"

        let bundle = Bundle(for: Self.self)
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
    }
    
    func testExportWithOneImage() throws {
        try exportWithOneImage()
    }
    
    @discardableResult
    func exportWithTwoImages() throws -> Place? {
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)

        let place = try Place.newObject()
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
        
        let location = try Location.newObject()
        place.addToLocations(location)
        
        let image = Image.newObject()
        image.fileName = imageInTestBundle
        location.addToImages(image)

        let image2 = Image.newObject()
        image2.fileName = imageInTestBundle2
        location.addToImages(image2)
        
        let urls:[URL]
        do {
            urls = try placeExporter.export(place: place)
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
    
    func testExportWithTwoImages() throws {
        try exportWithTwoImages()
    }
    
    func testExportDirectories() throws {
        try exportWithNoImages()
        
        let exportedPlaces: [PlaceExporter.ExportedPlace]
        do {
            exportedPlaces = try PlaceExporter.exportedPlaces(in: Self.exportURL)
        } catch {
            XCTFail()
            return
        }
        
        XCTAssert(exportedPlaces.count > 0)
        
        for exportedPlace in exportedPlaces {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: exportedPlace.location.path, isDirectory: &isDirectory) else {
                XCTFail()
                return
            }
            
            XCTAssert(isDirectory.boolValue)
        }
    }
    
    func testImportWithNoImages() throws {
        guard let (place, _, _) = try exportWithNoImages() else {
            XCTFail()
            return
        }
        
        guard let uuid = place.uuid else {
            XCTFail()
            return
        }
        
        let placeExportDirectory = place.exportDirectoryName(in: Self.exportURL)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
        
        guard try Place.fetchObject(withUUID: uuid) == nil else {
            XCTFail()
            return
        }
        
        guard let place2 = try Place.import(from: placeExportDirectory, in: Self.exportURL) else {
            XCTFail()
            return
        }
        XCTAssert(place2.uuid == uuid)
        
        // Make sure the place was saved as part of the import.
        XCTAssert(place2.changedValues().count == 0)
        
        guard try Place.fetchObject(withUUID: uuid) != nil else {
            XCTFail()
            return
        }
    }
        
    func testImportWithImages() throws {
        removePlaces()
        try FileManager.default.removeItem(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY))
        try? FileManager.default.createDirectory(at: FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY), withIntermediateDirectories: false, attributes: nil)
        
        guard let place = try exportWithTwoImages() else {
            XCTFail()
            return
        }
        
        guard place.largeImages.count == 2 else {
            XCTFail()
            return
        }
        
        // Need to remove files in the device's largeImages folder-- which are there because of exportWithTwoImages
        
        guard let fileName = place.largeImages[0].fileName,
            let fileName2 = place.largeImages[1].fileName else {
            XCTFail()
            return
        }
        
        let documentsImageURL = URL(fileURLWithPath: Image.filePath(for: fileName))
        let documentsImageURL2 = URL(fileURLWithPath: Image.filePath(for: fileName2))
        try FileManager.default.removeItem(at: documentsImageURL)
        try FileManager.default.removeItem(at: documentsImageURL2)

        let placeExportDirectory = place.exportDirectoryName(in: Self.exportURL)
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)

        guard let importedPlace = try Place.import(from: placeExportDirectory, in: Self.exportURL) else {
            XCTFail()
            return
        }
                
        guard let locations = importedPlace.locations as? Set<Location>,
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
    
    func testThatREADMEIsCreated() throws {
        let readMeURL = PlaceExporter.readMe(in: Self.exportURL)
        try? FileManager.default.removeItem(at: readMeURL)

        try PlaceExporter.initializeExport(directory: Self.exportURL)
        
        guard let contents = try getREADME() else {
            XCTFail()
            return
        }
        
        XCTAssert(contents == PlaceExporter.readMeContents)
    }
    
    private func getREADME() throws -> String? {
        let readMeURL = Self.exportURL.appendingPathComponent(PlaceExporter.readMe)
        let data = try Data(contentsOf: readMeURL)
        return String(data: data, encoding: .utf8)
    }
    
    // Need to also make sure that if the README contents are changed on the second export, that the update actually occurs.
    func testThatREADMEIsReplacedOnSecondExport() throws {
        let readMeURL = PlaceExporter.readMe(in: Self.exportURL)
        try? FileManager.default.removeItem(at: readMeURL)

        try PlaceExporter.initializeExport(directory: Self.exportURL)
        
        // Append to the README contents -- to test a "change"
        try FileManager.default.removeItem(at: readMeURL)
        let changedContents = PlaceExporter.readMeContents + "extra"
        
        guard let data = changedContents.data(using: .utf8) else {
            XCTFail()
            return
        }
        
        try data.write(to: readMeURL)
        
        // Make sure this second export doesn't fail.
        try PlaceExporter.initializeExport(directory: Self.exportURL)

        guard let contents = try getREADME() else {
            XCTFail()
            return
        }
        
        // make sure the contents *do not* reflect the changedContents
        XCTAssert(contents == PlaceExporter.readMeContents)
    }
    
    func testThatREADMEFileNameIsNotReturnedInFolderList() throws {
        // Also creates the README
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL)
        
        // Export a place.
        let place = try Place.newObject()
        place.name = "My Favorite Restaurant"
                
        do {
            try placeExporter.export(place: place)
        } catch {
            XCTFail()
            return
        }
        
        let exportedPlaces = try PlaceExporter.exportedPlaces(in: Self.exportURL)
        let filtered = exportedPlaces.filter {$0.location.lastPathComponent == PlaceExporter.readMe}
        
        XCTAssert(exportedPlaces.count > 0)
        XCTAssert(filtered.count == 0)
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func testRemoveExportedPlace() throws {
        guard let (place, exportPlaceJSONURL, placeExporter) = try exportWithNoImages(),
            let uuid = place.uuid else {
            XCTFail()
            return
        }
        
        let exportedPlaceURL = exportPlaceJSONURL.deletingLastPathComponent()
        
        try placeExporter.updateAlreadyExported()
        
        let removedPlaceURL = try placeExporter.removeExported(withUUID: uuid)
        
        guard !FileManager.default.fileExists(atPath: exportedPlaceURL.path) else {
            XCTFail()
            return
        }
        
        XCTAssert(exportedPlaceURL == removedPlaceURL)
    }
    
    // Tests that a change in the place name after export doesn't mess up later deletion. This is a good test because while the original export folder name is formed using the place name, the exported place removal method reconsititutes the folder name by starting (only) with the uuid of the place.
    func testRemoveExportedPlaceWithChangedPlaceName() throws {
        guard let (place, exportPlaceJSONURL, placeExporter) = try exportWithNoImages(),
            let uuid = place.uuid,
            let placeName = place.name else {
            XCTFail()
            return
        }
        
        try placeExporter.updateAlreadyExported()
        
        let exportedPlaceURL = exportPlaceJSONURL.deletingLastPathComponent()
        
        place.name = placeName + " Extra"
        
        let removedPlaceURL = try placeExporter.removeExported(withUUID: uuid)
        
        guard !FileManager.default.fileExists(atPath: exportedPlaceURL.path) else {
            XCTFail()
            return
        }
        
        XCTAssert(exportedPlaceURL == removedPlaceURL)
    }
    
    func testReExportAfterChangingPlaceNameShouldNotCreateAnotherExportDirectory() throws {
        removePlaces()
        
        let exportDirectoryURLs0 = try FileManager.default.contentsOfDirectory(atPath: Self.exportURL.path)

        // Don't initialize README because I don't want to count that in the directory contents.
        guard let (place, _, placeExporter) = try exportWithNoImages(initializeREADME: false),
            let placeName = place.name else {
            XCTFail()
            return
        }
        
        try placeExporter.updateAlreadyExported()
        
        let exportDirectoryURLs1 = try FileManager.default.contentsOfDirectory(atPath: Self.exportURL.path)

        XCTAssert(exportDirectoryURLs0.count + 1 == exportDirectoryURLs1.count)
        
        place.name = placeName + " Extra"
        
        do {
            try placeExporter.export(place: place)
        } catch {
            XCTFail()
        }
        
        try placeExporter.updateAlreadyExported()
        
        let exportDirectoryURLs2 = try FileManager.default.contentsOfDirectory(atPath: Self.exportURL.path)
        
        // The re-export should have used the same place export URL as the first export. Thus the number of export directories ought not to have changed.
        // This is: Despite the fact that the place name was changed, and the export place folder can't be reconstituted directly.
        
        XCTAssert(exportDirectoryURLs0.count + 1 == exportDirectoryURLs2.count)
    }
    
    func testCheckForReExportAfterNoChangeShouldNotNeedExport() throws {
        removePlaces()
        
        guard let (place, _, placeExporter) = try exportWithNoImages() else {
            XCTFail()
            return
        }
        
        try placeExporter.updateAlreadyExported()
        
        do {
            let needsExporting = try placeExporter.placeNeedsExporting(place)
            XCTAssert(!needsExporting)
        } catch {
            XCTFail()
        }
    }
    
    // Initially I had not covered this case. A re-export after removing a directory manually didn't actually re-export.
    func testReExportAfterPlaceDataInExportWasRemovedShouldActuallyExport() throws {
        removePlaces()
        
        guard let (place, _, placeExporter) = try exportWithNoImages() else {
            XCTFail()
            return
        }
        
        let placeExportFolder = place.exportDirectoryName(in: Self.exportURL)
        try FileManager.default.removeItem(at: placeExportFolder)
        
        try placeExporter.updateAlreadyExported()

        do {
            let needsExporting = try placeExporter.placeNeedsExporting(place)
            XCTAssert(needsExporting)
        } catch {
            XCTFail()
        }
    }
    
    func testCompareAllWithNoPlacesInCoreData() throws {
        removePlaces()
        Parameters.backupFolderBookmark.dataValue = Data()
        Parameters.displayBackupFolder.stringValue = ""
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, accessor: .none, initializeREADME: false)
        let result = try placeExporter.compareAll()
        XCTAssert(result.equal(.same))
    }
    
    func testCompareAllWithNoPlacesInCoreDataButExportedPlaces() throws {
        removePlaces()
        Parameters.backupFolderBookmark.dataValue = Data()
        Parameters.displayBackupFolder.stringValue = ""
        
        let place1 = try Place.newObject()
        let place2 = try Place.newObject()

        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, accessor: .none, initializeREADME: false)
        
        for place in [place1, place2] {
            try placeExporter.export(place: place)
        }
        
        try placeExporter.updateAlreadyExported()
        
        place1.remove()
        place2.remove()
        
        let result = try placeExporter.compareAll()
        XCTAssert(result.equal(.same))
    }
    
    func testCompareAllWithPlaceInCoreDataAndNoExport() throws {
        removePlaces()
        Parameters.backupFolderBookmark.dataValue = Data()
        Parameters.displayBackupFolder.stringValue = ""
        
        let place = try Place.newObject()
        
        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, accessor: .none, initializeREADME: false)
        let result = try placeExporter.compareAll()
        XCTAssert(result.equal(.different(.cannotFindPlaceInExport)))

        place.remove()
        XCTAssert(try Place.numberOfObjects() == 0)
    }
    
    func testCompareAllWithPlacesInCoreDataThatAreNotInExport() throws {
        removePlaces()
        Parameters.backupFolderBookmark.dataValue = Data()
        Parameters.displayBackupFolder.stringValue = ""
        
        let place1 = try Place.newObject()
        let place2 = try Place.newObject()

        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, accessor: .none, initializeREADME: false)
        
        for place in [place1, place2] {
            try placeExporter.export(place: place)
        }
        
        try placeExporter.updateAlreadyExported()
        
        let place3 = try Place.newObject()
        
        // So, now 3 places in core data, but only two of those in export.
                
        let result = try placeExporter.compareAll()
        XCTAssert(result.equal(.different(.notEnoughCoreDataPlaces)))

        place1.remove()
        place2.remove()
        place3.remove()

        XCTAssert(try Place.numberOfObjects() == 0)
    }
    
    func testCompareAllWithOneCoreDataPlaceRemovedAfterExport() throws {
        removePlaces()
        Parameters.backupFolderBookmark.dataValue = Data()
        Parameters.displayBackupFolder.stringValue = ""
        
        let place1 = try Place.newObject()
        let place2 = try Place.newObject()

        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, accessor: .none, initializeREADME: false)
        
        for place in [place1, place2] {
            try placeExporter.export(place: place)
        }
        
        try placeExporter.updateAlreadyExported()
                
        place1.remove()
        
        // Now, one of the places removed-- but the backup should still be sufficient.
                
        let result = try placeExporter.compareAll()
        XCTAssert(result.equal(.same))

        place2.remove()

        XCTAssert(try Place.numberOfObjects() == 0)
    }
    
    func testCompareAllWithChangedPlaceInCoreDataRelativeToExport() throws {
        removePlaces()
        Parameters.backupFolderBookmark.dataValue = Data()
        Parameters.displayBackupFolder.stringValue = ""
        
        let place1 = try Place.newObject()
        let place2 = try Place.newObject()

        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, accessor: .none, initializeREADME: false)
        
        for place in [place1, place2] {
            try placeExporter.export(place: place)
        }
        
        try placeExporter.updateAlreadyExported()
        
        place1.addToItems(try Item.newObject())
        
        // Now, one of the places in core data don't match those in export.
                
        do {
            let result = try placeExporter.compareAll()
            XCTAssert(result.equal(.different(.placesNotEqual)))
        } catch let error {
            XCTFail("\(error)")
        }
        
        place1.remove()
        place2.remove()

        XCTAssert(try Place.numberOfObjects() == 0)
    }
    
    func testCompareAllWithSameCoreDataAsExport() throws {
        removePlaces()
        Parameters.backupFolderBookmark.dataValue = Data()
        Parameters.displayBackupFolder.stringValue = ""
        
        let place1 = try Place.newObject()
        place1.addToItems(try Item.newObject())

        let place2 = try Place.newObject()
        place2.name = "Foobly"

        let placeExporter = try PlaceExporter(parentDirectory: Self.exportURL, accessor: .none, initializeREADME: false)
        
        for place in [place1, place2] {
            try placeExporter.export(place: place)
        }
        
        try placeExporter.updateAlreadyExported()
                        
        let result = try placeExporter.compareAll()
        XCTAssert(result.equal(.same))
        
        place1.remove()
        place2.remove()

        XCTAssert(try Place.numberOfObjects() == 0)
    }
}
