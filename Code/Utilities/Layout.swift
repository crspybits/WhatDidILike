//
//  Layout.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import UIKit

class Layout {
    static func format(textBox: UIView) {
        let layer = textBox.layer
        layer.borderColor = UIColor.textBoxLightGray.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 5.0
        textBox.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
    }
}
