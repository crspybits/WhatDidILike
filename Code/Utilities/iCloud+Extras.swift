//
//  iCloud+Extras.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/23/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import SMCoreLib

extension URL {
    enum ICloudError: Error {
        case wrongTypeForIsUbiquitousItem
    }
    
    func forceSync() throws {
        guard try inICloud() else {
            Log.msg("Folder \(self) was not in iCloud Drive")
            return
        }

        try FileManager.default.startDownloadingUbiquitousItem(at: self)
    }
    
    // Determine whether a folder or file is iCloud Drive or not.
    func inICloud() throws -> Bool {
        return FileManager.default.isUbiquitousItem(at: self)
        
        /*
        let result = try resourceValues(forKeys: [.isUbiquitousItemKey])
        guard let inICloud = result.allValues[.isUbiquitousItemKey] as? Bool else {
            throw ICloudError.wrongTypeForIsUbiquitousItem
        }
        */
    }
}
