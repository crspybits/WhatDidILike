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
    
    enum SortOrder : Int {
        case distance = 0
        case suggest = 1 // previously, "rating"
        case name = 2
    }
    
    private static let _sortingOrder = SMPersistItemInt(name: "Parameters.sortingOrder", initialIntValue: SortOrder.distance.rawValue, persistType: .userDefaults)
    static var sortingOrder:SortOrder {
        set {
            _sortingOrder.intValue = newValue.rawValue
        }
        get {
            if let result = SortOrder(rawValue: _sortingOrder.intValue) {
                return result
            }
            return SortOrder.distance
        }
    }
    
    // Separate out the ascending/descending values because I want these to persist even when a particular sort order is not selected.
    private static let _distanceAscending = SMPersistItemBool(name: "Parameters.distanceAscending", initialBoolValue: true, persistType: .userDefaults)
    static var distanceAscending: Bool {
        set {
            _distanceAscending.boolValue = newValue
        }
        
        get {
            return _distanceAscending.boolValue
        }
    }
    
    private static let _suggestAscending = SMPersistItemBool(name: "Parameters.ratingAscending", initialBoolValue: true, persistType: .userDefaults)
    static var suggestAscending: Bool {
        set {
            _suggestAscending.boolValue = newValue
        }
        
        get {
            return _suggestAscending.boolValue
        }
    }
    
    private static let _nameAscending = SMPersistItemBool(name: "Parameters.nameAscending", initialBoolValue: true, persistType: .userDefaults)
    static var nameAscending: Bool {
        set {
            _nameAscending.boolValue = newValue
        }
        
        get {
            return _nameAscending.boolValue
        }
    }
    
    static var sortingOrderIsAscending:Bool {
        switch sortingOrder {
        case .distance:
            return Parameters.distanceAscending
            
        case .suggest:
            return Parameters.suggestAscending
            
        case .name:
            return Parameters.nameAscending
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
    
    enum TryAgainFilter: String {
        case again = "Again"
        case notAgain = "Not Again"
        case dontUse = "Don't Use"
    }
    
    private static let _tryAgainFilter = SMPersistItemString(name: "Parameters.tryAgainFilter", initialStringValue: TryAgainFilter.dontUse.rawValue, persistType: .userDefaults)
    static var tryAgainFilter:TryAgainFilter {
        set {
            _tryAgainFilter.stringValue = newValue.rawValue
        }
        get {
            if let result = TryAgainFilter(rawValue: _tryAgainFilter.stringValue) {
                return result
            }
            return .dontUse
        }
    }
    
    enum DistanceFilter: String {
        case use = "Use"
        case dontUse = "Don't Use"
    }
    
    private static let _distanceFilter = SMPersistItemString(name: "Parameters.distanceFilter", initialStringValue: DistanceFilter.dontUse.rawValue, persistType: .userDefaults)
    static var distanceFilter:DistanceFilter {
        set {
            _distanceFilter.stringValue = newValue.rawValue
        }
        get {
            if let result = DistanceFilter(rawValue: _distanceFilter.stringValue) {
                return result
            }
            return .dontUse
        }
    }
    
    static var filterApplied:Bool {
        return distanceFilter == .use || tryAgainFilter != .dontUse
    }
    
    private static let _distanceFilterAmount = SMPersistItemInt(name: "Parameters.distanceFilterAmount", initialIntValue: 0, persistType: .userDefaults)
    // Units: Miles
    static var distanceFilterAmount:Int {
        set {
            _distanceFilterAmount.intValue = newValue
        }
        get {
            return _distanceFilterAmount.intValue
        }
    }
    
    enum Location : Int {
        case me = 0
        case address = 1
    }
    
    private static let _location = SMPersistItemInt(name: "Parameters.location", initialIntValue: Location.me.rawValue, persistType: .userDefaults)
    static var location:Location {
        set {
            _location.intValue = newValue.rawValue
        }
        get {
            if let result = Location(rawValue: _location.intValue) {
                return result
            }
            return .me
        }
    }
}
