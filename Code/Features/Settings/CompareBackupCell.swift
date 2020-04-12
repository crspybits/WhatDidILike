//
//  CompareBackupCell.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 4/8/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class CompareBackupCell: UITableViewCell, SettingsCellDelegate {
    weak var parentVC: UIViewController?
    @IBOutlet weak var compare: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCompare()
    }
    
    private func setupCompare() {
        let exportFolder = Parameters.getExportFolder(parentVC: parentVC)
        compare.isEnabled = exportFolder != nil
    }
    
    func backupFolder(isAvailable: Bool) {
        setupCompare()
    }
    
    @IBAction func compareAction(_ sender: Any) {
        guard let exportFolder = Parameters.getExportFolder(parentVC: parentVC) else {
            let alert = UIAlertController(title: "Alert!", message: "No export folder.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.parentVC?.present(alert, animated: true, completion: nil)
            return
        }

#if DEBUG
        var result: PlaceExporter.ComparisonResult!
        
        func cleanup() {
            let notification = Notification(name: Notification.Name(rawValue: MainListVC.createPlaceDataSourceNotification))
            NotificationCenter.default.post(notification)
        }
        
        do {
            let placeExporter = try PlaceExporter(parentDirectory: exportFolder, accessor: .securityScoped, initializeREADME: false)
            
            // Without this, I get a crash in the MainListVC-- because the `compareAll` internally creates temporary Places which mess with the CoreDataSource in the MainListVC.
            let notification = Notification(name: Notification.Name(rawValue: MainListVC.resetPlaceDataSourceNotification))
            NotificationCenter.default.post(notification)
            
            result = try placeExporter.compareAll()
            cleanup()
        } catch let error {
            cleanup()
            let alert = UIAlertController(title: "Alert!", message: "Comparison failed: \(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.parentVC?.present(alert, animated: true, completion: nil)
            return
        }
        
        let title:String
        var message: String?
        
        switch result! {
        case .same:
            title = "Same!!"
        case .different(let difference):
            title = "Different"
            message = "\(difference)"
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.parentVC?.present(alert, animated: true, completion: nil)
#endif
    }
}

