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
    // This is just to indicate to the user that they have selected a folder and is for display purposes. The real info is in the *bookmark*.
    private static let displayBackupFolder = SMPersistItemString(name: "Parameters.displayBackupFolder", initialStringValue: "", persistType: .userDefaults)
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var backupNow: UIButton!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var placesNeedingBackup: UILabel!
    weak var parentVC: UIViewController?
    private var backup: BackupWithAlert?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        Layout.format(textBox: textView)
        separator.backgroundColor = .separatorBackground
        setFolderTextInUI(Self.displayBackupFolder.stringValue)
    }
    
    func updatePlacesNeedingBackup() {
        if let (placesToExport, total) = Place.needExport(), placesToExport.count > 0 {
            let terms: String
            if total == 1 {
                terms = "place needs"
            }
            else {
                terms = "places need"
            }
            
            placesNeedingBackup.text = "(\(placesToExport.count) of \(total) \(terms) backup)"
            placesNeedingBackup.isHidden = false
        }
        else {
            placesNeedingBackup.isHidden = true
        }
    }
    
    @IBAction func selectAction(_ sender: Any) {
        let documentPicker =
            UIDocumentPickerViewController(documentTypes: [kUTTypeFolder as String], in: .open)
        documentPicker.delegate = self
        parentVC?.present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func backupNowAction(_ sender: Any) {
        guard let parentVC = parentVC else {
            return
        }
                
        let exportFolder: URL
        do {
            exportFolder = try URL.securityScopedResourceFromBookmark(data: Parameters.backupFolderBookmark.dataValue)
        } catch {
            let alert = UIAlertController(title: "Alert!", message: "Could not securely access the backup folder.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentVC.present(alert, animated: true, completion: nil)
            return
        }

        // So that while the backup is occuring, the user can't navigate to the places list and make changes to the places.
        parentVC.tabBarController?.tabBar.isUserInteractionEnabled = false

        backup = BackupWithAlert(parentVC: parentVC)
        backup!.start(usingSecurityScopedFolder: exportFolder) { [weak self] in
            self?.updatePlacesNeedingBackup()
            self?.backup = nil
            parentVC.tabBarController?.tabBar.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func clearAction(_ sender: Any) {
        Parameters.backupFolderBookmark.reset()
        Self.displayBackupFolder.stringValue = ""
        setFolderTextInUI(Self.displayBackupFolder.stringValue)
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
        
        guard let bookmarkData = try? urls[0].bookmarkForSecurityScopedResource() else {
            let alert = UIAlertController(title: "Alert!", message: "Failed creating bookmark for folder.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentVC?.present(alert, animated: true, completion: nil)
            return
        }
        
        Parameters.backupFolderBookmark.dataValue = bookmarkData
        
        Self.displayBackupFolder.stringValue = urls[0].path
        setFolderTextInUI(Self.displayBackupFolder.stringValue)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
}
