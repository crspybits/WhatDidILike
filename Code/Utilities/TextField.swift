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
        saveIfNeeded()
        endEditing(false)
    }
    
    fileprivate func saveIfNeeded(trim: Bool = true) {
        if trim {
            text = text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        
        if previousValue != text {
            save?(text!)
        }
    }
    
    @objc private func cancelButtonAction() {
        text = previousValue
        endEditing(false)
    }
}

extension TextField : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        previousValue = textField.text
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveIfNeeded()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if let update = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) {
            textField.text = update
            // Don't trim here because if I do that the user can't enter white space. `textViewDidChange` gets called on every key tapped, including white space.
            saveIfNeeded(trim: false)
        }

        return false
    }
}
