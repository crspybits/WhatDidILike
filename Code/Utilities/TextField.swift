//
//  TextField.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/11/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import UIKit

class TextField : UITextField {
    var save:((_ update: String)->())?
    var previousValue:String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let screenWidth = UIScreen.main.bounds.width
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: screenWidth, height: 30))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(cancelButtonAction))
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonAction))
        
        toolbar.setItems([cancelButton, flexSpace, saveButton], animated: false)
        toolbar.sizeToFit()

        inputAccessoryView = toolbar
        
        delegate = self
    }
    
    @objc private func saveButtonAction() {
        endEditing(false)
        
        if previousValue != text {
            save?(text!)
        }
    }
    
    @objc private func cancelButtonAction() {
        endEditing(false)
        text = previousValue
    }
}

extension TextField : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        previousValue = textField.text
    }
}
