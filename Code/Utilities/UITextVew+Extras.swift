//
//  UITextView+Extras.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/10/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

extension UITextView {    
    func addToolBar() {
        // let toolbar = UITextField.makeToolBar(doneButtonTarget: self, andAction: #selector(doneButtonAction))
        //inputAccessoryView = toolbar
    }
    
    @objc private func doneButtonAction() {
        endEditing(false)
    }
}
