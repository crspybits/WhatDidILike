//
//  Spinner.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/1/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol SpinnerObject {
    var spinner:Spinner! {get}
}

class Spinner : UIActivityIndicatorView {

    // set `makeBigger` to nil if you don't want it bigger.
    // centers spinner on the superview.
    init(activityIndicatorStyle: UIActivityIndicatorViewStyle = .gray, makeBigger scaleFactor:CGFloat? = 2.0, superview:UIView) {
        super.init(activityIndicatorStyle: activityIndicatorStyle)
        
        if let scaleFactor = scaleFactor {
            let transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
            self.transform = transform
        }
        
        superview.addSubview(self)
        center = superview.center
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // Trying to deal with rotation.
    override func layoutSubviews() {
        super.layoutSubviews()
        center = superview!.center
    }
    
    func start() {
        startAnimating()
    }
    
    func stop() {
        stopAnimating()
    }
}
