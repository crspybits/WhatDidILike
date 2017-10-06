//
//  NewLocation.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/5/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class NewLocation: UIView, XibBasics {
    typealias ViewType = NewLocation
    var newLocation:(()->())?

    @IBAction func newLocationAction(_ sender: Any) {
        newLocation?()
    }
}
