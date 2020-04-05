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
    
    /* Decodes a single place from the given place export directory, creating the needed managed objects.
        If needed, images are copied into the large images directory in the Documents directory from the place export directory.
        Two types of uuid collision can occur as a result of this call:
        1) The creationDate of the colliding uuid in the imported place differs from the creationDate in the core data Place it is colliding with. In this case a new necessarily different ("real") UUID is allocated. Really, this is the (albeit) unlikely event that when creating the new Place object, a real UUID collision occurred. Saves the place returned before returning.
        2) The creationDates are the same. In this case, nil is returned and no Place managed object is created.
    */
    @discardableResult
    static func `import`(from placeExportDirectory: URL, in parentDirectory: URL, accessor:URL.Accessor = .none) throws -> Place? {
        let jsonFileName = URL(fileURLWithPath: placeExportDirectory.path + "/" + placeJSON)
        var place:Place!
        
        // I initially thought that I needed to access the jsonFileName as security scoped, but nope. That fails. Need to do security scoped access on the parentDirectory.
        
        try parentDirectory.accessor(accessor) { url in
            let jsonData = try Data(contentsOf: jsonFileName)
            let importPlacePeek = try Place.partialDecode(data: jsonData)

            guard let importUUID = importPlacePeek.uuid else {
                throw ImportExportError.noUUIDInPlaceJSON
            }

            let havePlaceUuidCollision: Bool
            switch try Place.alreadyExists(uuid: importUUID) {
            case .exists:
                // This is not the type of collision being reported by Place. Something is seriously wrong!
                throw ImportExportError.wrongInternalCollisionResult
                
            case .existsWithObject(let collidingPlace):
                if collidingPlace.creationDate == importPlacePeek.creationDate {
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
            
            let decoder = JSONDecoder()
            place = try decoder.decode(Place.self, from: jsonData)
            
            // TODO: Need collision avoidance on UUID's for images.

            /* So, if we get a UUID collision across existing Place uuid's and exported Place uuid's, we previously always caused the import to stop. Now, instead doing the following:
                1) Generate a new (distinct) UUID for this imported Place.
                2) Rely on some other method/process to clean up later. E.g., garbage collection to remove the now duplicated place in the export folders.
            */
            
            if havePlaceUuidCollision {
                place.uuid = try Place.realUUID()
            }
            
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
                        // Collision. Need to rename the `image` with a different UUID. Upon the next backup, this image will be duplicated in the backup. It will be present at it's prior name. And it will be present at the new name.
                        let newUUID: String = try Image.realUUID()
                        image.uuid = newUUID
                        imageFileName = Image.createFileName(usingNewImageFileUUID: newUUID)
                        image.fileName = imageFileName
                    }
                    // Else: No collision-- use the original file name.
                }
                // Else: The image.uuid is nil. This must be a pre-v2.2 image-- it's not named with the UUID. Just use the original file name.
                                    
                let appImageURL = URL(fileURLWithPath: Image.filePath(for: imageFileName))

                do {
                    try FileManager.default.copyItem(at: exportedImageURL, to: appImageURL)
                } catch let error {
                    CoreData.sessionNamed(CoreDataExtras.sessionName).remove(place)
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
