//
//  TextView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/11/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

import Foundation
import UIKit

class TextView : UITextView {
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
        
        if previousValue != text, let text = text {
            save?(text)
        }
    }
    
    @objc private func cancelButtonAction() {
        text = previousValue
        endEditing(false)
    }
}

extension TextView : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        previousValue = textView.text
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // This will take place even if the user just changes to editing a different field. By default, I'm going to save changes.
        saveIfNeeded()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Don't trim here because if I do that the user can't enter white space. `textViewDidChange` gets called on every key tapped, including white space.
        saveIfNeeded(trim: false)
    }
}
