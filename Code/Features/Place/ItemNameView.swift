//
//  ItemNameView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class ItemNameView: UIView, XibBasics {
    typealias ViewType = ItemNameView
    @IBOutlet weak var itemName: TextField!
    var showHide: (()->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: itemName)
        itemName.addToolBar()
    }
    
    @IBAction func showHideAction(_ sender: Any) {
        showHide?()
    }
}
