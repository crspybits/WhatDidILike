//
//  UITextField+Extras.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/10/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

extension UITextField {
    static func makeToolBar(doneButtonTarget: Any?, andAction action: Selector?) -> (UIToolbar, UIBarButtonItem)  {
        let screenWidth = UIScreen.main.bounds.width
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: screenWidth, height: 30))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: doneButtonTarget, action: action)
        
        toolbar.setItems([flexSpace, doneButton], animated: false)
        toolbar.sizeToFit()
       
        return (toolbar, doneButton)
    }
    
    func addToolBar() {
        //let toolbar = UITextField.makeToolBar(doneButtonTarget: self, andAction: #selector(doneButtonAction))
        //inputAccessoryView = toolbar
    }
    
    /*
    @objc private func doneButtonAction() {
        endEditing(false)
    }*/
}
