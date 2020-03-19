//
//  ConvertFromV2.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/19/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

// A migration to add id's to places for import/export purposes.

import Foundation
import SMCoreLib

class ConvertFromV2 {
    private static let migrated = SMPersistItemBool(name: "ConvertFromV2.migrated", initialBoolValue: false, persistType: .userDefaults)

    static func doIt() {
        guard !migrated.boolValue else {
            return
        }
        
        migrated.boolValue = true

        guard let places = Place.fetchAllObjects() else {
            return
        }
        
        for place in places {
            place.id = Place.nextId as NSNumber
            place.save()
        }
    }
}
