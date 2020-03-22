//
//  ImportExport.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/16/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

protocol ImportExport {
    // The names of the large image files, within the relevant directory. The names don't contain the directory path.
    var largeImageFiles: [String] {get}
}
