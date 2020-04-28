//
//  Codable+Extras.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 4/27/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

enum CodableExtras {
    static let format = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    
    static func equalDates(_ d1: Date?, _ d2: Date?) -> Bool {
        if d1 == nil && d2 == nil {
            return true
        }
        
        guard let d1 = d1, let d2 = d2 else {
            // We know that only one of the dates was nil, not both. Thus, they are not equal.
            return false
        }
        
        let delta = 0.001
        let interval1 = d1.timeIntervalSinceReferenceDate
        let interval2 = d2.timeIntervalSinceReferenceDate
        let diff = abs(interval1 - interval2)
        return diff < delta
    }
}

private var dateFormat: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = CodableExtras.format

    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    
    return formatter
}

extension JSONDecoder {
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormat)
        return decoder
    }
}

extension JSONEncoder {
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormat)
        return encoder
    }
}

