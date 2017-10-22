//
//  PlaceNameView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib

class PlaceNameView: UIView, XibBasics {
    typealias ViewType = PlaceNameView
    @IBOutlet weak var placeName: TextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: placeName)
    }
    
    deinit {
        Log.msg("deinit")
    }
}
