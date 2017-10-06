//
//  NewObject.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/5/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class NewObject: UIView, XibBasics {
    typealias ViewType = NewObject
    var new:(()->())?
    @IBOutlet private weak var button: UIButton!
    
    func setButton(name: String) {
        button.setTitle(name, for: .normal)
    }
    
    @IBAction func newAction(_ sender: Any) {
        new?()
    }
}
