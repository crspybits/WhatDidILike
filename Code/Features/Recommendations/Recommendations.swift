//
//  Recommendations.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/11/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

/* Recommendations, aka, suggestions. I'm going to make these place-based. I'm doing this because I assume that each location of a place is similar, and all data for locations for a place combine together. Each location of a place will share the same recommendation value. Suggestion values are >= 0. Larger suggestion values mean they are more highly recommended.
 */

protocol Recommendations {
    // Determine the number of distinct days on which we have data for a particular place. The intuition is: If we have been to the place multiple times we like it, and have data on multiple days.
    // TODO: This can be supplemented later with an overt means to "check-in" to a place/location to explicitly add to this "number of distinct days".
    
    // The dates returned will not necessarily be on different days.
    var dates: [Date] {get}
}

extension Recommendations {
    func fileCreationDate(filePath: String) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: filePath) as NSDictionary
        return attrs?.fileCreationDate()
    }
    
    var Khours: Int {
        3
    }
    
    var Kseconds: TimeInterval {
        TimeInterval(Khours * 60 * 60)
    }
    
    // This does a segmentation of a sorted list of dates. Two neighboring dates are considered to be distinct only if they are separated by at least K hours.
    func numberOfDistinctDates(_ dates: [Date]) -> Int {
        var result = dates.count > 0 ? 1 : 0
        
        // Put dates into increasing order
        let dates = dates.sorted()
        var index = 1
        
        while index < dates.count {
            let diff = abs(dates[index].timeIntervalSince(dates[index-1]))
            if diff >= Kseconds {
                result += 1
            }
            
            index += 1
        }
        
        return result
    }
}
