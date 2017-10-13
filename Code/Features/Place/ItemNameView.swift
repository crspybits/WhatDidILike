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
    @IBOutlet weak var addCommentButton: UIButton!
    var showHide: ((_ state: ShowHideState)->())?
    private var showHideState:ShowHideState = .closed
    @IBOutlet private weak var openClosed: UIImageView!
    
    var delete:(()->())?
    var addComment:(()->())?
    var commentViewsForItem = [RowView]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addCommentButton.isHidden = Parameters.commentStyle == .single
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
        var rotationAngle:Float
        
        switch showHideState {
        case .closed:
            rotationAngle = -Float.pi/2.0
            showHideState = .open
            
        case .open:
            rotationAngle = 0
            showHideState = .closed
        }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.openClosed.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle));
        }) { (success) in
            // Doing this after the animation because I'm doing a table view reload which interferes with the animation.
            self.showHide?(self.showHideState)
        }
    }
    
    @IBAction func addCommentAction(_ sender: Any) {
        addComment?()
    }
}
