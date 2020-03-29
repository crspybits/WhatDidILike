//
//  PlaceExporter.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/28/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

class PlaceExporter {
    let parentDirectory: URL
    let accessor:URL.Accessor
    private(set) var alreadyExported: [ExportedPlace]!

    init(parentDirectory: URL, accessor:URL.Accessor = .none,
        initializeREADME: Bool = true) throws {
        
        self.parentDirectory = parentDirectory
        self.accessor = accessor
        
        if initializeREADME {
            try Self.initializeExport(directory: parentDirectory, accessor: accessor)
        }
        
        alreadyExported = try Self.exportedPlaces(in: parentDirectory, accessor: accessor)
    }
    
    // Because every time you export a new place, or remove an exported place, the exportedPlaces change.
    func updateAlreadyExported() throws {
        alreadyExported = try Self.exportedPlaces(in: parentDirectory, accessor: accessor)
    }
    
    // Copies a README.txt file to the export directory. Replaces the current one if there is already one there.
    static func initializeExport(directory: URL, accessor: URL.Accessor = .none) throws {
        try directory.accessor(accessor) { url in
            // Remove existing one first. In case we've updated the README text in the app.
            let readMeURL = readMe(in: directory)
            if FileManager.default.fileExists(atPath: readMeURL.path) {
                try FileManager.default.removeItem(at: readMeURL)
            }
            
            guard let data = readMeContents.data(using: .utf8) else {
                throw ImportExportError.couldNotConvertREADMEToData
            }
            
            try data.write(to: readMeURL)
        }
    }
    
    static let readMe = "README.txt"
    static var readMeContents: String {
        return """
            You should not change any files or folders in this folder if you want to later do a restore using this data into the WhatDidILike app. Or if you want to later export the WhatDidILike data again.
            You should also not add any files or folders to this folder, for the same reason.
        """
    }
    
    static func readMe(in directory: URL) -> URL {
        let readMePath = directory.path + "/" + readMe
        return URL(fileURLWithPath: readMePath)
    }
    
    struct ExportedPlace {
        // The full URL of the place in the exported directory, e.g., iCloud
        // The form of the last component will have been formatted the first time the place is exported, and will remain the same even if the user changes the place name in WhatDidILike.
        let location: URL
        
        let uuid: String
    }
    
    // Returns the ExportedPlace of all of the exported place directories in the export parentDirectory.
    /* Example use cases:
        1) In order to do a restore, need a list of all previously exported places.
        2) In order to do a forceSync of folders not yet downloaded from iCloud.
        3) To get the export folder of a place, e.g., to delete it when a place is deleted or when re-exporting a previously exported place.
    */
    static func exportedPlaces(in parentDirectory: URL, accessor:URL.Accessor = .none) throws -> [ExportedPlace] {
        let fileManager = FileManager.default
       
        var urls:[URL]!
        try parentDirectory.accessor(accessor) { url in
            urls = try fileManager.contentsOfDirectory(at: parentDirectory, includingPropertiesForKeys: nil)
        }
        
        let filteredURLs = urls.filter {$0.lastPathComponent != readMe}
        
        return try filteredURLs.map { url -> ExportedPlace in
            let uuid = try Place.getUUIDFrom(url: url)
            return ExportedPlace(location: url, uuid: uuid)
        }
    }
    
    // Returns the ExportedPlace of the given place if it has already been exported. Returns nil otherwise.
    func exportedPlace(place: Place) throws -> ExportedPlace? {
        guard let uuid = place.uuid else {
            throw ImportExportError.uuidOfPlaceNotFound
        }
        
        return exportedPlace(placeUUID: uuid)
    }
    
    // Relies on the `alreadyExported`s as being up to date.
    func exportedPlace(placeUUID uuid: String) -> ExportedPlace? {
        let filtered = alreadyExported.filter {$0.uuid == uuid}
        
        if filtered.count == 0 {
            return nil
        }
        
        return filtered[0]
    }
    
    // Attempts to create a child directory, in the parent directory, using the form:
    //  <CleanedPlaceName>_<uuid>
    // where <CleanedPlaceName> has any non-alphabetic/non-numeric characters replaced with underscores.
    // On a re-export of this same place, the existing export directory is used, even if the place name was changed. The contents are removed from that directory in this case.
    // Writes JSON and image files for the place to this directory.
    // Returns the URL's of the exported files.
    // Doesn't do a save for Core Data, but this ought to be done by caller since the lastExport field (of self) was changed.
    @discardableResult
    func export(place: Place) throws -> [URL] {
        
        var imageURLs = [URL]()
        var jsonFileName:URL!
        
        // Access to the security scoped URL appears only necessary at the top-level directory. I don't need to do the access step for the sub-directories or files within those sub-directories.
        
        try parentDirectory.accessor(accessor) { url in
            let exportDirectory: URL
            
            // Has this place already been exported?
            if let exportedPlace = try exportedPlace(place: place) {
                exportDirectory = exportedPlace.location
                try place.reCreateDirectory(placeExportDirectory: exportedPlace.location)
            }
            else {
                // First time this place is being exported.
                exportDirectory = try place.createNewDirectory(in: parentDirectory)
            }
        
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(place)
            
            jsonFileName = URL(fileURLWithPath: exportDirectory.path + "/" + Place.placeJSON)
            
            guard FileManager.default.createFile(atPath: jsonFileName.path, contents: jsonData, attributes: nil) else {
                throw ImportExportError.cannotCreateJSONFile
            }

            for imageFileName in place.largeImageFiles {
                let originalImageURL = URL(fileURLWithPath: Image.filePath(for: imageFileName))
                let exportImageURL = URL(fileURLWithPath: exportDirectory.path + "/" + imageFileName)
                try FileManager.default.copyItem(at: originalImageURL, to: exportImageURL)
                
                imageURLs += [exportImageURL]
            }
        }
        
        place.lastExport = Date()
        
        return [jsonFileName] + imageURLs
    }
    
    // Attempts to force a download sync of already exported places iCloud Drive. This method is here to address the following problems I've been having with a failure synchronization. First, on the simulator, only the place folders in iCloud Drive download, not their contents. (Going into the Files app into a place folder does cause contents to download). Second, for a specific place.json file for one place I modified manually on the iCloud Drive web UI, this is now showing up as missing on my iPhone.
    // Always uses security scoped accessor-- this can't easily be tested in unit tests.
    // This is adapted from https://stackoverflow.com/questions/33462352
    static func forceSync(foldersIn cloudDriveDirectory: URL) throws {
        let alreadyExported = try Self.exportedPlaces(in: cloudDriveDirectory, accessor: .securityScoped)
        try cloudDriveDirectory.accessor(.securityScoped) { url in
            for exportedPlace in alreadyExported {
                try exportedPlace.location.forceSync()
            }
        }
    }
    
    // Removes a folder and all contents for the place given the UUID.
    // Returns the URL of the place export folder just removed.
    // Assumes the place indicated by the UUID has already been exported.
    @discardableResult
    func removeExported(withUUID uuid: String) throws -> URL {
        guard let alreadyExported = exportedPlace(placeUUID: uuid) else {
            throw ImportExportError.uuidOfPlaceNotFound
        }

        let placeURLToRemove = alreadyExported.location
        
        try parentDirectory.accessor(accessor) { url in
            try FileManager.default.removeItem(at: placeURLToRemove)
        }
        
        return alreadyExported.location
    }
}
