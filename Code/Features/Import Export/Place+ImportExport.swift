//
//  Place+ImportExport.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/19/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

extension Place {
    static let placeJSON = "place.json"
    
    enum ImportExportError: Error {
        case cannotCreateJSONFile
        case cannotDeserializeToDictionary
        case noIdInPlaceJSON
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
    
    // Decodes a place from the given place export directory, creating the needed managed objects.
    // If not present already, images are copied into the large images directory in the Documents directory from the place export directory.
    // Returns nil if a Place with the exported id already exists in Core Data. Returns non-nil otherwise.
    static func `import`(from placeExportDirectory: URL) throws -> Place? {
        let jsonFileName = URL(fileURLWithPath: placeExportDirectory.path + "/" + placeJSON)
        
        let jsonData = try Data(contentsOf: jsonFileName)
        
        // Before decoding, make sure id we are decoding isn't in an existing place.
        guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            throw ImportExportError.cannotDeserializeToDictionary
        }
        
        guard let id = dict[Place.CodingKeys.id.rawValue] as? Place.IdType else {
            throw ImportExportError.noIdInPlaceJSON
        }
        
        guard try Place.fetchObject(withId: id) == nil else {
            return nil
        }

        let decoder = JSONDecoder()
        let place = try decoder.decode(Place.self, from: jsonData)
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
}
