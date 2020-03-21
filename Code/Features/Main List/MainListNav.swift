//
//  MainListNav.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/20/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class MainListNav: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func create() -> Self {
        return UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "MainListNav") as! Self
    }
}
