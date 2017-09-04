//
//  XibBasics.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import UIKit
import SMCoreLib

protocol XibBasics {
    associatedtype ViewType
}

extension XibBasics {
    static func create() -> ViewType? {
        guard let viewType = Bundle.main.loadNibNamed(typeName(self), owner: self, options: nil)?[0] as? ViewType else {
            Log.error("Error: Could not load view!")
            assert(false)
            return nil
        }
        
        let view = viewType as! UIView
        view.autoresizingMask = [.flexibleWidth]
        
        return viewType
    }
}
