//
//  Tabs.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/20/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class Tabs: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let mainListNav = MainListNav.create()
        let settings = SettingsNav.create()
        
        let vcs = [mainListNav, settings]
        viewControllers = vcs
        
        if let items = tabBar.items, items.count == vcs.count {
            let mainList = items[0]
            mainList.image = UIImage(named: "place")
            
            let settings = items[1]
            settings.image = UIImage(named: "settings")
        }
    }
}
