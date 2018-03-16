//
//  OrderFilter.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/15/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

// Wrapping this enum in a class to implement NSCoding
class OrderFilter : NSObject, NSCoding {
    var orderFilter: OrderFilterType

    init(_ orderFilter: OrderFilterType) {
        self.orderFilter = orderFilter
    }
    
    enum OrderFilterType {
        case name(ascending: Bool)
        case distance(ascending: Bool)
        case rating(ascending: Bool)
        
        init?(orderType: UInt, ascending: Bool) {
            switch orderType {
            case 0:
                self = .name(ascending: ascending)
            case 1:
                self = .distance(ascending: ascending)
            case 2:
                self = .rating(ascending: ascending)

            default:
                return nil
            }
        }
    
        func toRawValues() -> (orderType:Int64, ascending:Bool) {
            switch self {
            case .name(let ascending):
                return(0, ascending)

            case .distance(let ascending):
                return (1, ascending)
                
            case .rating(let ascending):
                return (2, ascending)
            }
        }
        
        var isAscending:Bool {
            switch self {
            case .name(let ascending):
                return ascending

            case .distance(let ascending):
                return ascending
                
            case .rating(let ascending):
                return ascending
            }
        }
        
        func to(ascending: Bool) -> OrderFilterType {
            switch self {
            case .name:
                return .name(ascending: ascending)

            case .distance:
                return .distance(ascending: ascending)
                
            case .rating:
                return .rating(ascending: ascending)
            }
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        let orderValues = self.orderFilter.toRawValues()

        aCoder.encode(orderValues.orderType, forKey: "orderType")
        aCoder.encode(orderValues.ascending, forKey: "ascending")
    }

    public required init?(coder aDecoder: NSCoder) {
        let orderType = aDecoder.decodeInteger(forKey: "orderType")
        let ascending = aDecoder.decodeBool(forKey: "ascending")
        
        guard let orderFilter = OrderFilterType(orderType: UInt(orderType), ascending: ascending) else {
            return nil
        }

        self.orderFilter = orderFilter

        super.init()
    }
}
