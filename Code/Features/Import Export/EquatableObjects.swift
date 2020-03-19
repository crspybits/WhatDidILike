//
//  EquatableObjects.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/19/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

protocol EquatableObjects where Self: Hashable {
    static func equal(_ lhs: Self?, _ rhs: Self?) -> Bool
}

extension EquatableObjects {
    static func equal(_ set1: Set<Self>?, _ set2: Set<Self>?) -> Bool {
        if let set1 = set1, let set2 = set2 {
            guard set1.count == set2.count else {
                return false
            }
            
            for obj1 in set1 {
                var found = false
                for obj2 in set2 {
                    if equal(obj1, obj2) {
                        found = true
                        break
                    }
                }
                
                if !found {
                    return false
                }
            }
            
            return true
        }
        else {
            return set1 == set2
        }
    }
    
    static func equal(_ array1 : [Self]?, _ array2: [Self]?) -> Bool {
        if let array1 = array1, let array2 = array2 {
            guard array1.count == array2.count else {
                return false
            }
            
            for index in 0..<array2.count {
                let obj1 = array1[index]
                let obj2 = array2[index]
                guard equal(obj1, obj2) else {
                    return false
                }
            }
            
            return true
        }
        else {
            return array1 == array2
        }
    }
}

