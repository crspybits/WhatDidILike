//
//  ImportExport.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/16/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

// Exporting: Per place, need to save JSON of Place and sub-objects. And save files associated with place (i.e., image files).

// Need id/key's for places. Simplest to just use integers. Need to do a migration to establish. And for subsequent place creation assign next highest. Need this for file or folder names when exporting to make names unique.

// Need a mechanism to compare two places for equality-- presumably something like a tree comparison.
