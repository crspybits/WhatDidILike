//
//  GPS+Extras.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/15/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import FLAnimatedImage

protocol GPSDelegate : class {
    func startedUsingGPS(_ obj: Any)
    func stoppedUsingGPS(_ obj: Any)
}

class GPSExtras {
    static func spinner() -> (FLAnimatedImageView, UIBarButtonItem) {
        let gifURL = Bundle.main.url(forResource: "rotatingEarth", withExtension: "gif")
        let gifData = try! Data(contentsOf: gifURL!)
        let image = FLAnimatedImage(animatedGIFData: gifData)
        let animatingEarthImageView = FLAnimatedImageView()
        animatingEarthImageView.animatedImage = image
        animatingEarthImageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let earthBarButtonItem = UIBarButtonItem(customView: animatingEarthImageView)
        animatingEarthImageView.isHidden = true
        return (animatingEarthImageView, earthBarButtonItem)
    }
}
