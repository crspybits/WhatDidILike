//
//  Layout.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import UIKit
import DGRunkeeperSwitch

class Layout {
    static func format(textBox: UIView) {
        let layer = textBox.layer
        layer.borderColor = UIColor.textBoxLightGray.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 5.0
        textBox.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
    }
    
    static func format(comment: UIView) {
        let layer = comment.layer
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 20.0
        comment.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
    }
    
    static func format(location: UIView) {
        let layer = location.layer
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 20.0
        location.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
    }
    
    static func format(`switch`: DGRunkeeperSwitch, usingSize size: CGSize) {
        `switch`.selectedBackgroundColor = .white
        `switch`.titleColor = .white
        `switch`.backgroundColor = UIColor.lightGray
        `switch`.selectedTitleColor = UIColor(red: 239.0/255.0, green: 95.0/255.0, blue: 49.0/255.0, alpha: 1.0)
        `switch`.titleFont = UIFont(name: "HelveticaNeue-Medium", size: 17.0)
        `switch`.frame = CGRect(x: 0, y: 0, width: size.width, height:size.height)
    }
}
