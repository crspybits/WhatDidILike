//
//  Parameters.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/12/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import SMCoreLib

class Parameters {
    enum CommentStyle : String {
    case single
    case multiple
    }
    
    private static let _commentStyle = SMPersistItemString(name: "Parameters.commentStyle", initialStringValue: CommentStyle.single.rawValue, persistType: .userDefaults)
    static var commentStyle:CommentStyle {
        set {
            _commentStyle.stringValue = newValue.rawValue
        }
        get {
            return CommentStyle(rawValue: _commentStyle.stringValue)!
        }
    }

    private static let _orderFilter = SMPersistItemData(name: "Parameters.orderFilter", initialDataValue: Data(), persistType: .userDefaults)
    static var orderFilter:OrderFilter.OrderFilterType {
        set {
            let obj = OrderFilter(newValue)
            _orderFilter.dataValue = NSKeyedArchiver.archivedData(withRootObject: obj)
        }
        get {
            if let obj = NSKeyedUnarchiver.unarchiveObject(with: _orderFilter.dataValue) as? OrderFilter {
                return obj.orderFilter
            }
            else {
                // A default. Something bad happened.
                Log.error("Yikes: Couldn't unarchive the Sorting.Order object!")
                return .distance(ascending: true)
            }
        }
    }
    
    static let limitLocationServicesFailed = 3
    static let numberOfTimesLocationServicesFailed = SMPersistItemInt(name: "Parameters.numberOfTimesLocationServicesFailed", initialIntValue: 0, persistType: .userDefaults)
}
