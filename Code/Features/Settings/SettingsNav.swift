//
//  SettingsNav.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/20/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class SettingsNav: UINavigationController {
    static func create() -> Self {
        return UIStoryboard(name: "Settings", bundle: nil)
            .instantiateViewController(withIdentifier: "SettingsNav") as! Self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
