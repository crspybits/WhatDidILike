//
//  RatingView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import DGRunkeeperSwitch
import TTGEmojiRate
import SMCoreLib

class RatingView: UIView, XibBasics {
    typealias ViewType = RatingView
    static let ratingViewHeight: CGFloat = 170
    @IBOutlet weak var rateView: EmojiRateView!
    @IBOutlet weak var switchView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let meThemSwitch = DGRunkeeperSwitch()
        meThemSwitch.titles = ["Me", "Them"]
        meThemSwitch.selectedBackgroundColor = .white
        meThemSwitch.titleColor = .white
        meThemSwitch.backgroundColor = UIColor.lightGray
        meThemSwitch.selectedTitleColor = UIColor(red: 239.0/255.0, green: 95.0/255.0, blue: 49.0/255.0, alpha: 1.0)
        meThemSwitch.titleFont = UIFont(name: "HelveticaNeue-Medium", size: 17.0)
        meThemSwitch.frame = CGRect(x: 0, y: 0, width: switchView.frameWidth, height:switchView.frameHeight)
        switchView.addSubview(meThemSwitch)
        
        rateView.backgroundColor = UIColor.clear
        rateView.rateValueChangeCallback = { rateValue in
            Log.msg("rateValue: \(rateValue)")
        }
    }
}
