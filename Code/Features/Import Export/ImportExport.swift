//
//  ImportExport.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/16/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

// On Place import, need to assign place id to highest value imported.

// Need a UI to enable user to control this import/export.

// When a place managed object is removed, any corresponding directory in the export directory also needs to be removed.

// When a place is imported, do I need to be concerned with image name conflicts? I.e., that a name for an image already exists in the large images directory?

// DONE: Export: For a single place, write to files: (a) the Place (and substructure) JSON, and (b) the image files.

// DONE: Import: For a single place, read from files: (a) the Place (and substructure) JSON, and (b) the image files.

// DONE: Need a mechanism to compare two places for equality-- presumably something like a tree comparison.

// DONE: On export, need to update lastExport property of a Place.

// DONE: Exporting: Per place, need to save JSON of Place and sub-objects. And save files associated with place (i.e., image files).

// DONE: Need id/key's for places. Simplest to just use integers. Need to do a migration to establish. And for subsequent place creation assign next highest. Need this for file or folder names when exporting to make names unique.

// DONE: Need to have modification date on a Place updated when ever any of its children change. Or have a way to compute this. That modification date is to enable backing up of changed places to storage.

protocol ImportExport {
    // The names of the large image files, within the relevant directory. The names don't contain the directory path.
    var largeImageFiles: [String] {get}
}
