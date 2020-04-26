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

protocol SettingsCellDelegate: AnyObject {
    func backupFolder(isAvailable: Bool)
    func startSpinner()
    func stopSpinner()
}

extension SettingsCellDelegate {
    // Make the spinner methods optional
    func startSpinner() {}
    func stopSpinner() {}
}

class SyncSettingsCell: UITableViewCell {
    weak var delegate: SettingsCellDelegate?
    @IBOutlet weak var sync: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var backupNow: UIButton!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var placesNeedingBackup: UILabel!
    @IBOutlet weak var restoreNow: UIButton!
    weak var parentVC: UIViewController?
    private var backup: BackupWithAlert?
    private var restore: RestoreWithAlert?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        placesNeedingBackup.text = ""
        updatePlacesNeedingBackup()
        
        Layout.format(textBox: textView)
        separator.backgroundColor = .separatorBackground
        setFolderTextInUI(Parameters.displayBackupFolder.stringValue)
        
        Log.msg("Parameters.displayBackupFolder.stringValue: \(Parameters.displayBackupFolder.stringValue)")

        syncICloudIfNeeded(showUIIndications: false)
    }
    
    private func syncICloudIfNeeded(showUIIndications: Bool) {
        guard let exportFolder = Parameters.getExportFolder(parentVC: parentVC) else {
            return
        }
    
        guard let inICloud = try? exportFolder.inICloud(), inICloud else {
            return
        }
        
        if showUIIndications {
            delegate?.startSpinner()
        }
        
        DispatchQueue.global(qos: .background).async {
            do {
                try PlaceExporter.forceSync(foldersIn: exportFolder)
                
                if showUIIndications {
                    let message = "If there are files that need downloading from the cloud -- downloading may take a while after you do this. e.g., don't do a Restore yet."
                    DispatchQueue.main.async {
                        self.delegate?.stopSpinner()
                        let alert = UIAlertController(title: "Sync Started!", message: message, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.parentVC?.present(alert, animated: true, completion: nil)
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    self.delegate?.stopSpinner()
                }
                Log.error("Failed to forceSync: \(error)")
            }
        }
    }
    
    func updatePlacesNeedingBackup() {
        guard let exportFolder = Parameters.getExportFolder(parentVC: parentVC) else {
            return
        }
                
        var placeExporter: PlaceExporter!
        var totalPlaces:UInt!
        
        do {
            totalPlaces = try Place.numberOfObjects()
            placeExporter = try PlaceExporter(parentDirectory: exportFolder, accessor: .securityScoped)
        } catch let error {
            Log.msg("\(error)")
            return
        }
        
        if let placesToExport = try? placeExporter.needExport(),
            placesToExport.count > 0 {
            let terms: String
            if totalPlaces == 1 {
                terms = "place needs"
            }
            else {
                terms = "places need"
            }
            
            placesNeedingBackup.text = "(\(placesToExport.count) of \(totalPlaces!) \(terms) backup)"
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
        guard let parentVC = parentVC,
            let exportFolder = Parameters.getExportFolder(parentVC: parentVC) else {
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
        Parameters.displayBackupFolder.stringValue = ""
        setFolderTextInUI(Parameters.displayBackupFolder.stringValue)
        
        delegate?.backupFolder(isAvailable: false)
    }
    
    private func setFolderTextInUI(_ text: String) {
        var iCloudFolder = false
        if let exportFolder = Parameters.getExportFolder(parentVC: parentVC),
            let iCloud = try? exportFolder.inICloud() {
            iCloudFolder = iCloud
        }
    
        let enableButtons = text != ""
        backupNow.isEnabled = enableButtons
        restoreNow.isEnabled = enableButtons
        sync.isEnabled = enableButtons && iCloudFolder
        textView.text = text
    }
    
    @IBAction func restoreAction(_ sender: Any) {
        guard let parentVC = parentVC,
            let exportFolder = Parameters.getExportFolder(parentVC: parentVC) else {
            return
        }
        
        // So that while the restore is occuring, the user can't navigate to the places list and make changes to the places.
        parentVC.tabBarController?.tabBar.isUserInteractionEnabled = false

        restore = RestoreWithAlert(parentVC: parentVC)
        restore!.start(usingSecurityScopedFolder: exportFolder) { [weak self] in
            self?.restore = nil
            self?.updatePlacesNeedingBackup()
            parentVC.tabBarController?.tabBar.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func syncAction(_ sender: Any) {
        syncICloudIfNeeded(showUIIndications: true)
    }
    
    @IBAction func helpAction(_ sender: Any) {
        guard let helpViewer = HelpViewerVC.create(toViewHelpFile: "backupHelp.html") else {
            return
        }
        
        parentVC?.navigationController?.pushViewController(helpViewer, animated: true)
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
        Place.resetLastExports()
        
        updatePlacesNeedingBackup()
        Parameters.displayBackupFolder.stringValue = urls[0].path
        setFolderTextInUI(Parameters.displayBackupFolder.stringValue)
        
        delegate?.backupFolder(isAvailable: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    }
}
