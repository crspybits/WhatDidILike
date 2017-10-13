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
}
