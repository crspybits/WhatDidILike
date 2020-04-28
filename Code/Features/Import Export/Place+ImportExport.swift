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
    
    // Makes the name only; doesn't check the actual directory for the existence of this directory.
    func exportDirectoryName(in parentDirectory: URL) -> URL {
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
        
        // Problems with this, downstream
        // return URL(fileURLWithPath: fileName, relativeTo: parentDirectory)
        
        return parentDirectory.appendingPathComponent(fileName)
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
        let directoryName = exportDirectoryName(in: parentDirectory)
        
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
    
    static func peek(with placeExportDirectory: URL, in parentDirectory: URL, accessor:URL.Accessor = .none) throws -> (placeData: Data, PartialPlace) {
        let jsonFileName = URL(fileURLWithPath: placeExportDirectory.path + "/" + placeJSON)
    
        // I initially thought that I needed to access the jsonFileName as security scoped, but nope. That fails. Need to do security scoped access on the parentDirectory.
    
        var partialPlace: PartialPlace!
        var jsonData:Data!
        
        try parentDirectory.accessor(accessor) { url in
            jsonData = try Data(contentsOf: jsonFileName)
            partialPlace = try Place.partialDecode(data: jsonData)
        }
    
        return (jsonData, partialPlace)
    }
    
    /* Decodes a single place from the given place export directory, creating the needed managed objects.
        If needed, images are copied into the large images directory in the Documents directory from the place export directory.
        Two types of uuid collision can occur as a result of this call:
        1) The creationDate of the colliding uuid in the imported place differs from the creationDate in the core data Place it is colliding with. In this case a new necessarily different ("real") UUID is allocated. Really, this is the (albeit) unlikely event that when creating the new Place object, a real UUID collision occurred. Saves the place returned before returning. In addition, the place export directory is renamed to reflect this new UUID.
        2) The creationDates are the same. In this case, nil is returned and no Place managed object is created.
        
        `testing`-- If you set this to true (for debug builds only), then (a) no place UUID conflict resolution is done, and (b) images from export are not copied into app.
        
        On an import failure, a cleanup is done so Core Data objects remain and no files remain from attempted import.
    */
    @discardableResult
    static func `import`(from placeExportDirectory: URL, in parentDirectory: URL, accessor:URL.Accessor = .none, testing: Bool = false) throws -> Place? {
        var placeExportDirectory = placeExportDirectory
        var place:Place!
                
        let (jsonData, importPlacePeek) = try peek(with: placeExportDirectory, in: parentDirectory, accessor: accessor)
 
         guard let importUUID = importPlacePeek.uuid else {
             throw ImportExportError.noUUIDInPlaceJSON
         }
 
        try parentDirectory.accessor(accessor) { url in
            var havePlaceUuidCollision = false
            
            if !testing {
                switch try Place.alreadyExists(uuid: importUUID) {
                case .exists:
                    // This is not the type of collision being reported by Place. Something is seriously wrong!
                    throw ImportExportError.wrongInternalCollisionResult
                    
                case .existsWithObject(let collidingPlace):
                    if CodableExtras.equalDates(collidingPlace.creationDate as Date?, importPlacePeek.creationDate as Date?) {
                        // The place we are importing has the same creation date as the UUID collision. I'm taking this to mean: The place we are importing is really the same place, and we're not just having a UUID collision.
                        // It seems important to emphasize that this isn't really a UUID collision. It's more of a possible conflict where we might want to try to integrate changes from a backup (if, say, it's stored in iCloud) with local changes. For now, not going to worry about this.
                        Log.msg("Import attempt of place with same UUID and same creationDate: Skipping")
                        return // to get out of `parentDirectory.accessor`
                    }
                    else {
                        // The place we are importing has a different creation date than the UUID collision. Presumably, this is the rare real collision-- where places are being imported into a set of meaningfully different other places.
                        havePlaceUuidCollision = true
                    }
                case .doesNotExist:
                    havePlaceUuidCollision = false
                }
            }
            
            let decoder = JSONDecoder.decoder
            place = try decoder.decode(Place.self, from: jsonData)
            
            if testing {
                return // to get out of `parentDirectory.accessor`
            }
            
            /* So, if we get a UUID collision across existing Place uuid's and exported Place uuid's, we previously always caused the import to stop. Now, instead doing the following:
                1) Generate a new (distinct) UUID for this imported Place.
                2) Rename old export folder to new one based on new UUID.
            */
            
            if havePlaceUuidCollision {
                // Need to rename directory where the place export is stored to reflect a new UUID.
                let originalPlaceExportDirectory = placeExportDirectory
                
                // Setup the new UUID
                place.uuid = try Place.realUUID()
                
                let newPlaceExportDirectory = place.exportDirectoryName(in: parentDirectory)
                
                try FileManager.default.moveItem(at: originalPlaceExportDirectory, to: newPlaceExportDirectory)
                
                placeExportDirectory = newPlaceExportDirectory
            }
            
            // Copy images from export into app.
            
            for image in place.largeImages {
                // Use existing names or do we have a UUID collision? Since we've already dealt with Place UUID collisions we know we're importing a new Place.
                // NOTE: This is a rather different use case than for Place's. The Image managed objects *already* exist. This means that if we have a UUID collision for an Image, then two Image's, with the same UUID, will exist in Core Data.
                
                guard let originalFileName = image.fileName else {
                    throw ImportExportError.imageHasNoFileName
                }

                // The file name for the exported image needs no change. It's just present in the backup.
                let exportedImageURL = URL(fileURLWithPath: placeExportDirectory.path + "/" + originalFileName)
                
                var imageFileName = originalFileName
                
                if let imageUUID = image.uuid {
                    // This is a post-v2.2 image-- Do we have a UUID collision?
                    guard let images = try Image.fetchAllObjects(withUUID: imageUUID) else {
                        throw ImportExportError.noImagesFoundForExistingUUID
                    }
                    
                    if images.count > 1 {
                        // Collision. Upon the next backup, this image will be duplicated in the backup. It will be present at it's prior name. And it will be present at the new name.
                        // Note that the place.json in the export still reflects the old (colliding) image naming.
                        // On a full cleanup, we'd need to update the place.json with the new uuid naming, and rename the image file in the export on this basis.
                        // For now, I'm going to not worry about either of these. This may be best done in a garbage collection manner and not here-- this code is complicated enough as it stands and I can't see modifying the place.json file in an import.

                        let newUUID: String = try Image.realUUID()
                        image.uuid = newUUID
                        imageFileName = Image.createFileName(usingNewImageFileUUID: newUUID)
                        image.fileName = imageFileName
                    }
                    // Else: No collision-- use the original file name.
                }
                // Else: The image.uuid is nil. This must be a pre-v2.2 image-- it's not named with a UUID. Just use the original file name.
                                    
                let appImageURL = URL(fileURLWithPath: Image.filePath(for: imageFileName))

                do {
                    try FileManager.default.copyItem(at: exportedImageURL, to: appImageURL)
                } catch let error {
                    // Remove any locations as part of this removal/error handling.
                    // All the substructure for the place must get removed.
                    // And any images copied so far ought to be removed.
                    
                    if let locations = place.locations as? Set<Location> {
                        var unusedUuid: String?
                        for location in locations {
                            location.remove(uuidOfPlaceRemoved: &unusedUuid)
                        }
                        
                        if unusedUuid == nil {
                            Log.msg("ERROR: Why wasn't the place removed in the cleanup?")
                        }
                    }
                    else {
                        // Shouldn't get here, but put it in just in case. I.e., any place ought to have had a location and we should have used the above code to do the cleanup.
                        place.remove()
                    }
                    
                    CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()

                    throw ImportExportError.errorCopyingFile(error)
                }
            }
        }
        
        if place == nil {
            // Case: UUID collision and collidingPlace.creationDate == importPlacePeek.creationDate
            return nil
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
