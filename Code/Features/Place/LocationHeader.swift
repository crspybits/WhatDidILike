//
//  LocationHeader.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/5/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

class LocationHeader : UIView, XibBasics {
    typealias ViewType = LocationHeader
    @IBOutlet private weak var address: UILabel!
    private var location:Location!
    
    @IBOutlet private weak var openClosed: UIImageView!
    private var showHideState:ShowHideState = .closed
    var showHide: ((_ state: ShowHideState)->())?

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
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(withLocation location: Location) {
        self.location = location
        address.text = location.address
    }
}
