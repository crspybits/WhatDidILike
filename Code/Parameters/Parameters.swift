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

    private static let _orderFilter = SMPersistItemData(name: "Parameters.orderFilter", initialDataValue: NSKeyedArchiver.archivedData(withRootObject: OrderFilter(.name(ascending: true))), persistType: .userDefaults)
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
    
    static let userName = SMPersistItemString(name: "Parameters.userName", initialStringValue: "", persistType: .userDefaults)
    
    private static let _sortLocation = SMPersistItemData(name: "Parameters.sortLocation", initialDataValue: NSKeyedArchiver.archivedData(withRootObject: CLLocation()), persistType: .userDefaults)
    static var sortLocation:CLLocation? {
        set {
            _sortLocation.dataValue = NSKeyedArchiver.archivedData(withRootObject: newValue as Any)
        }
        get {
            if let obj = NSKeyedUnarchiver.unarchiveObject(with: _sortLocation.dataValue) as? CLLocation {
                return obj
            }
            else {
                // A default. Something bad happened.
                Log.error("Yikes: Couldn't unarchive the sortLocations object!")
                return nil
            }
        }
    }
    
    private static let _orderAddress = SMPersistItemString(name: "Parameters.orderAddress", initialStringValue: "", persistType: .userDefaults)
    static var orderAddress:String {
        set {
            _orderAddress.stringValue = newValue
        }
        get {
            return _orderAddress.stringValue
        }
    }
    
    enum FilterTryAgain: Int {
        case yes = 0
        case no = 1
        case off = 2
    }
    
    private static let _filterTryAgain = SMPersistItemInt(name: "Parameters.filterTryAgain", initialIntValue: FilterTryAgain.off.rawValue, persistType: .userDefaults)
    static var filterTryAgain:FilterTryAgain {
        set {
            _filterTryAgain.intValue = newValue.rawValue
        }
        get {
            if let result = FilterTryAgain(rawValue: _filterTryAgain.intValue) {
                return result
            }
            return .off
        }
    }
    
    enum FilterDistance: Int {
        case on = 0
        case off = 1
    }
    
    private static let _filterDistance = SMPersistItemInt(name: "Parameters.filterDistance", initialIntValue: FilterDistance.off.rawValue, persistType: .userDefaults)
    // Units: Miles
    static var filterDistance:FilterDistance {
        set {
            _filterDistance.intValue = newValue.rawValue
        }
        get {
            if let result = FilterDistance(rawValue: _filterDistance.intValue) {
                return result
            }
            return .off
        }
    }
    
    private static let _filterDistanceAmount = SMPersistItemInt(name: "Parameters.filterDistanceAmount", initialIntValue: 0, persistType: .userDefaults)
    static var filterDistanceAmount:Int {
        set {
            _filterDistanceAmount.intValue = newValue
        }
        get {
            return _filterDistanceAmount.intValue
        }
    }
}
