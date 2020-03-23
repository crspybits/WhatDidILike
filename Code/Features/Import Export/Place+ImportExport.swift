//
//  Place+ImportExport.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/19/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import SMCoreLib

extension Place {
    static let placeJSON = "place.json"
    
    enum ImportExportError: Error {
        case cannotCreateJSONFile
        case cannotDeserializeToDictionary
        case noIdInPlaceJSON
        case exportedIdAlreadyExistsInCoreData
        case errorCopyingFile(Error)
        case couldNotGetLargeImagesFolder
        case wrongTypeForIsUbiquitousItem
    }
    
    // Attempts to create a child directory, in the parent directory, using the form:
    //  <CleanedPlaceName>_<id>
    // where <CleanedPlaceName> has any non-alphabetic/non-numeric characters replaced with underscores.
    // If this directory already exists, all contents are first removed.
    // Writes JSON and image files for the place to this directory.
    // Returns the URL's of the exported files.
    // Doesn't do a save for Core Data, but this ought to be done by caller since the lastExport field was changed.
    @discardableResult
    func export(to parentDirectory: URL, accessor: URL.Accessor = .none) throws -> [URL] {
        
        var imageURLs = [URL]()
        var jsonFileName:URL!
        
        // Access to the security scoped URL appears only necessary at the top-level directory. I don't need to do the access step for the sub-directories or files within those sub-directories.
        
        try parentDirectory.accessor(accessor) { url in
            let exportDirectoryName = try createDirectory(in: parentDirectory)

            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(self)
            
            jsonFileName = URL(fileURLWithPath: exportDirectoryName.path + "/" + Self.placeJSON)
            
            guard FileManager.default.createFile(atPath: jsonFileName.path, contents: jsonData, attributes: nil) else {
                throw ImportExportError.cannotCreateJSONFile
            }

            for imageFileName in largeImageFiles {
                let originalImageURL = URL(fileURLWithPath: Image.filePath(for: imageFileName))
                let exportImageURL = URL(fileURLWithPath: exportDirectoryName.path + "/" + imageFileName)
                try FileManager.default.copyItem(at: originalImageURL, to: exportImageURL)
                
                imageURLs += [exportImageURL]
            }
        }
        
        lastExport = Date()
        
        return [jsonFileName] + imageURLs
    }
    
    func createDirectoryName(in parentDirectory: URL) -> URL {
        var fileName = ""
        if let name = name?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), name.count > 0 {
            for char in name {
                if char.isLetter || char.isNumber {
                    fileName += String(char)
                }
                else {
                    fileName += "_"
                }
            }
            
            fileName += "_"
        }
        
        if let id = id?.int32Value {
            fileName += String(id)
        }
        
        return URL(fileURLWithPath: fileName, relativeTo: parentDirectory)
    }
    
    // If the directory (see createDirectoryName) doesn't exist, it is created.
    // If it does exist, with any contents, it is removed and recreated.
    func createDirectory(in parentDirectory: URL) throws -> URL {
        let directoryName = createDirectoryName(in: parentDirectory)
        
        if FileManager.default.fileExists(atPath: directoryName.path) {
            try FileManager.default.removeItem(at: directoryName)
        }
        
        try FileManager.default.createDirectory(at: directoryName, withIntermediateDirectories: false, attributes: nil)
        
        return directoryName
    }
    
    // Returns the full URL's of all of the exported place directories in the export parentDirectory.
    static func exportDirectories(in parentDirectory: URL, accessor:URL.Accessor = .none) throws -> [URL] {
        let fileManager = FileManager.default
       
        var urls:[URL]!
        try parentDirectory.accessor(accessor) { url in
            urls = try fileManager.contentsOfDirectory(at: parentDirectory, includingPropertiesForKeys: nil)
        }
        
        return urls
    }
    
    // Creates folder in the Documents folder if it's not there.
    static func createLargeImagesDirectoryIfNeeded() throws {
        guard let largeImagesDirectory = FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY) else {
            throw ImportExportError.couldNotGetLargeImagesFolder
        }
        
        if !FileManager.default.fileExists(atPath: largeImagesDirectory.path) {
            try? FileManager.default.createDirectory(at: largeImagesDirectory, withIntermediateDirectories: false, attributes: nil)
        }
    }
    
    // Decodes a single place from the given place export directory, creating the needed managed objects.
    // Images are copied into the large images directory in the Documents directory from the place export directory.
    // Saves the placed returned before returning.
    @discardableResult
    static func `import`(from placeExportDirectory: URL, in parentDirectory: URL, accessor:URL.Accessor = .none) throws -> Place {
        let jsonFileName = URL(fileURLWithPath: placeExportDirectory.path + "/" + placeJSON)
        var place:Place!
        
        // I initially though that I needed to access the jsonFileName as security scoped, but nope. That fails. Need to use the parentDirectory.
        
        try parentDirectory.accessor(accessor) { url in
            let jsonData = try Data(contentsOf: jsonFileName)

            // Before decoding, make sure id we are decoding isn't in an existing place.
            guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                throw ImportExportError.cannotDeserializeToDictionary
            }
            
            guard let id = dict[Place.CodingKeys.id.rawValue] as? Place.IdType else {
                throw ImportExportError.noIdInPlaceJSON
            }
            
            guard try Place.fetchObject(withId: id) == nil else {
                throw ImportExportError.exportedIdAlreadyExistsInCoreData
            }

            let decoder = JSONDecoder()
            place = try decoder.decode(Place.self, from: jsonData)
            
            if place.largeImageFiles.count > 0 {
                for imageFileName in place.largeImageFiles {
                    let deviceImageURL = URL(fileURLWithPath: Image.filePath(for: imageFileName))
                    let exportedImageURL = URL(fileURLWithPath: placeExportDirectory.path + "/" + imageFileName)
                    do {
                        try FileManager.default.copyItem(at: exportedImageURL, to: deviceImageURL)
                    } catch let error {
                        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
                        throw ImportExportError.errorCopyingFile(error)
                    }
                }
            }
        }
        
        // This sequence is a little hard to understand. i.e., it was hard to get right when developing. First, do an initial save so that all the modification dates of the place and sub-objects (e.g., Location's) get updated via their `willSave` calls.
        place.save()
        
        // This seems a little odd, but is suitable. Immediately after an import, we don't want to have place needing export.
        place.lastExport = Date()
        
        // Then do another save, to save the lastExport change.
        place.lastExport = Date()
        
        return place
    }
    
    // Return the collection of places that are "dirty"-- that have been changed since their last export (or that have never been exported).
    static func needExport() -> ([Place], totalNumber: Int)? {
        guard let allPlaces = Place.fetchAllObjects() else {
            return nil
        }
        
        var result = [Place]()
        
        for place in allPlaces {
            if let lastExport = place.lastExport {
                if place.lastExportModificationDate > lastExport {
                    // There was a change to the place after the last export. Need to re-export the place.
                    result += [place]
                }
            }
            else {
                // No lastExport date -- it needs exporting for the first time.
                result += [place]
            }
        }
        
        return (result, allPlaces.count)
    }
    
    // Attempts to force a download sync of iCloud Drive. I've been having problems with this in two ways so far. First, on the simulator, only the place folders in iCloud Drive download, not their contents. (Going into the Files app into a place folder does cause contents to download). Second, for a specific place.json file for one place I modified manually on the iCloud Drive web UI, this is now showing up as missing on my iPhone.
    // Always uses security scoped accessor-- this can't easily be tested in unit tests.
    // This is adapted from https://stackoverflow.com/questions/33462352
    static func forceSync(foldersIn cloudDriveDirectory: URL) throws {
        let urls = try Place.exportDirectories(in: cloudDriveDirectory, accessor: .securityScoped)
        
        try cloudDriveDirectory.accessor(.securityScoped) { url in
            for url in urls {
                try url.forceSync()
            }
        }
    }
        

    

}
