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
    @IBOutlet private weak var openClosed: UIImageView!
    private let animationDuration:TimeInterval = 0.1
    @IBOutlet private weak var header: UIView!
    @IBOutlet private weak var footer: UIView!
    
    var showHideState:ShowHideState = .closed {
        didSet {
            var rotationAngle:Float
            
            switch showHideState {
            case .open:
                rotationAngle = -Float.pi/2.0
                
            case .closed:
                rotationAngle = 0
            }
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.openClosed.transform = CGAffineTransform(rotationAngle: CGFloat(rotationAngle));
            }) { (success) in
                // Doing this after the animation because I'm doing a table view reload which interferes with the animation.
                self.showHide?(self.showHideState)
            }
        }
    }
    
    var delete:(()->())?
    var addComment:(()->())?
    var commentViewsForItem = [RowView]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addCommentButton.isHidden = Parameters.commentStyle == .single
        Layout.format(textBox: itemName)
        itemName.autocapitalizationType = .words
        itemName.addToolBar()
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction))
        gesture.direction = .left
        addGestureRecognizer(gesture)
    }
    
    @objc private func swipeAction() {
        delete?()
    }
    
    @IBAction func showHideAction(_ sender: Any) {
        switch showHideState {
        case .closed:
            showHideState = .open
            // Just because it's odd to have this open if there's no comments...
            // And because this is fun :).
            if commentViewsForItem.count == 0 {
                TimedCallback.withDuration(Float(animationDuration * 3)) { [unowned self] in
                    self.showHideState = .closed
                }
            }
        case .open:
            showHideState = .closed
        }
    }
    
    @IBAction func addCommentAction(_ sender: Any) {
        addComment?()
    }
    
    deinit {
        Log.msg("deinit")
    }
}
