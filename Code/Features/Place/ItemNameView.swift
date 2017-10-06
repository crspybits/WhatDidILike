//
//  ItemNameView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib

class ItemNameView: UIView, XibBasics {
    typealias ViewType = ItemNameView
    @IBOutlet weak var itemName: TextField!
    var showHide: (()->())?
    var delete:(()->())?
    var addComment:(()->())?
    var commentViewsForItem = [RowView]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: itemName)
        itemName.addToolBar()
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction))
        gesture.direction = .left
        addGestureRecognizer(gesture)
    }
    
    @objc private func swipeAction() {
        delete?()
    }
    
    @IBAction func showHideAction(_ sender: Any) {
        showHide?()
    }
    
    @IBAction func addCommentAction(_ sender: Any) {
        addComment?()
    }
}
