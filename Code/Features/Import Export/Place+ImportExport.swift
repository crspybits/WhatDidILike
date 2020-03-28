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
    
    static let separator = "_"
    
    func createDirectoryName(in parentDirectory: URL) -> URL {
        var fileName = ""
        if let name = name?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), name.count > 0 {
            for char in name {
                if char.isLetter || char.isNumber {
                    fileName += String(char)
                }
                else {
                    fileName += Self.separator
                }
            }
            
            fileName += Self.separator
        }
        
        if let uuid = uuid {
            fileName += uuid
        }
        
        return URL(fileURLWithPath: fileName, relativeTo: parentDirectory)
    }
    
    // Pull the uuid out of the last component of the URL
    static func getUUIDFrom(url: URL) throws -> String {
        let lastComponentParts = url.lastPathComponent.split(separator: Character(separator))
        guard lastComponentParts.count > 0,
            let uuidString = lastComponentParts.last else {
            throw ImportExportError.tooFewPartsInExportedPlaceURL
        }
        
        // Convert to a UUID so we know if we have valid UUID.
        guard let result = UUID(uuidString: String(uuidString))?.uuidString else {
            throw ImportExportError.invalidUUIDInExportedPlaceURL
        }
        
        return result
    }
    
    // Assumes the place has already been exported. Removes it and recreates it.
    func reCreateDirectory(placeExportDirectory: URL) throws {
        try FileManager.default.removeItem(at: placeExportDirectory)
        try FileManager.default.createDirectory(at: placeExportDirectory, withIntermediateDirectories: false, attributes: nil)
    }
    
    // Assumes the place has not already been exported.
    func createNewDirectory(in parentDirectory: URL) throws -> URL {
        let directoryName = createDirectoryName(in: parentDirectory)
        
        guard !FileManager.default.fileExists(atPath: directoryName.path) else {
            throw ImportExportError.placeExportDirectoryAlreadyExists
        }
        
        try FileManager.default.createDirectory(at: directoryName, withIntermediateDirectories: false, attributes: nil)
        
        return directoryName
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
    // Saves the place returned before returning.
    @discardableResult
    static func `import`(from placeExportDirectory: URL, in parentDirectory: URL, accessor:URL.Accessor = .none) throws -> Place {
        let jsonFileName = URL(fileURLWithPath: placeExportDirectory.path + "/" + placeJSON)
        var place:Place!
        
        // I initially thought that I needed to access the jsonFileName as security scoped, but nope. That fails. Need to do security scoped access on the parentDirectory.
        
        try parentDirectory.accessor(accessor) { url in
            let jsonData = try Data(contentsOf: jsonFileName)

            // Before decoding, make sure id we are decoding isn't in an existing place.
            guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                throw ImportExportError.cannotDeserializeToDictionary
            }
            
            guard let uuid = dict[Place.CodingKeys.uuid.rawValue] as? String else {
                throw ImportExportError.noUUIDInPlaceJSON
            }
            
            guard try Place.fetchObject(withUUID: uuid) == nil else {
                throw ImportExportError.exportedUUIDAlreadyExistsInCoreData
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
        
        // The following code sequence is a little hard to understand. i.e., it was hard to get right when developing.
        
        // First, do an initial save so that all the modification dates of the place and sub-objects (e.g., Location's) get updated via their `willSave` calls. Without this, the lastExport date will not fall *after* those modification dates.
        place.save()
        
        // This seems a little odd, but is suitable. Immediately after an import, we don't want to have place needing export.
        place.lastExport = Date()
        
        // Then do another save, to save the lastExport change.
        place.save()
        
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
        
    // If the backup folder is changed, need to reset the lastExport field of all places-- to force export to the new backup location.
    static func resetLastExports() {
        guard let places = Place.fetchAllObjects() else {
            return
        }
        
        for place in places {
            place.lastExport = nil
            place.save()
        }
    }
}
