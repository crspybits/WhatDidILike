//
//  ImportExport.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/16/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

enum ImportExportError: Error {
    case cannotCreateJSONFile
    case noUUIDInPlaceJSON
    case errorCopyingFile(Error)
    case couldNotGetLargeImagesFolder
    case wrongTypeForIsUbiquitousItem
    case couldNotConvertREADMEToData
    case tooFewPartsInExportedPlaceURL
    case invalidUUIDInExportedPlaceURL
    case uuidOfPlaceNotFound
    case placeExportDirectoryAlreadyExists
    case wrongInternalCollisionResult
    case imageHasNoFileName
    case noImagesFoundForExistingUUID
}

protocol ImportExport {
    // The Image's for the large image files, within the relevant directory.
    var largeImages: [Image] {get}
}
