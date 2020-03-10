//
//  UIColor+Extras.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    private static func colorMode(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return dark
                } else {
                    return light
                }
            }
        } else {
            return light
        }
    }
    
    static var textBoxBorder: UIColor {
        return colorMode(
            light: UIColor(white: 0.95, alpha: 1.0),
            dark: UIColor(white: 0.20, alpha: 1.0))
    }
    
    static var segmentedControlBorder: UIColor {
        let light = UIColor.gray
        let dark = UIColor(white: 0.80, alpha: 1.0)
        return colorMode(light: light, dark: dark)
    }
    
    static var textBoxBackground: UIColor {
        let light = UIColor(white: 0.85, alpha: 1.0)
        let dark = UIColor(white: 0.40, alpha: 1.0)
        return colorMode(light: light, dark: dark)
    }
    
    static var locationBackground: UIColor {
        let light = UIColor(white: 0.95, alpha: 1.0)
        let dark = UIColor.black
        return colorMode(light: light, dark: dark)
    }
    
    static var locationHeaderBackground: UIColor {
        let light = UIColor.white
        let dark = UIColor.black
        return colorMode(light: light, dark: dark)
    }
    
    static var commentBackground: UIColor {
        return locationBackground
    }
    
    static var modalBackground: UIColor {
        let light = UIColor(white: 0.95, alpha: 1.0)
        let dark = UIColor.black
        return colorMode(light: light, dark: dark)
    }
    
    static var sortyFilterBackground: UIColor {
        let light = UIColor(white: 0.95, alpha: 1.0)
        let dark = UIColor(white: 0.30, alpha: 1.0)
        return colorMode(light: light, dark: dark)
    }
    
    static var dropDownBackground: UIColor {
        let light = UIColor(white: 0.85, alpha: 1.0)
        let dark = UIColor(white: 0.20, alpha: 1.0)
        return colorMode(light: light, dark: dark)
    }
    
    static var tableViewBackground: UIColor {
        let light = UIColor(white: 0.95, alpha: 1.0)
        let dark = UIColor.black
        return colorMode(light: light, dark: dark)
    }
    
    static var openClosed: UIColor {
        let light = UIColor.black
        let dark = UIColor.white
        return colorMode(light: light, dark: dark)
    }
    
    static var upDown: UIColor {
        let light = UIColor.black
        let dark = UIColor.white
        return colorMode(light: light, dark: dark)
    }
    
    static var trash: UIColor {
        return locked
    }
    
    static var locked: UIColor {
        let light = UIColor.black
        let dark = UIColor(white: 0.8, alpha: 1.0)
        return colorMode(light: light, dark: dark)
    }
}
