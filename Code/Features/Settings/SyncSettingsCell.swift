//
//  SyncSettingsCell.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/20/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib
import CoreServices

class SyncSettingsCell: UITableViewCell {
    private static let backupFolder = SMPersistItemString(name: "SyncSettingsCell.backupFolder", initialStringValue: "", persistType: .userDefaults)
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var backupNow: UIButton!
    weak var parentVC: UIViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        Layout.format(textBox: textView)
        setFolderTextInUI(Self.backupFolder.stringValue)
    }
    
    @IBAction func selectAction(_ sender: Any) {
        let documentPicker =
            UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
        documentPicker.delegate = self
        parentVC?.present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func backupNowAction(_ sender: Any) {
    }
    
    @IBAction func clearAction(_ sender: Any) {
        Self.backupFolder.stringValue = ""
        setFolderTextInUI(Self.backupFolder.stringValue)
    }
    
    private func setFolderTextInUI(_ text: String) {
        backupNow.isEnabled = text != ""
        textView.text = text
    }
}

extension SyncSettingsCell: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard urls.count > 0 else {
            return
        }
        
        Self.backupFolder.stringValue = urls[0].path
        setFolderTextInUI(Self.backupFolder.stringValue)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
}
