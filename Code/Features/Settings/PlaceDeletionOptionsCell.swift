//
//  PlaceDeletionOptionsCell.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/26/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib

class PlaceDeletionOptionsCell: UITableViewCell {
    @IBOutlet weak var yesNo: UISegmentedControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        yesNo.selectedSegmentIndex = Parameters.removeBackupPlace.boolValue ? 0 : 1
        yesNo.isEnabled = (try? Parameters.securityScopedExportFolder()) != nil
    }
    
    @IBAction func yesNoAction(_ sender: Any) {
        Parameters.removeBackupPlace.boolValue = yesNo.selectedSegmentIndex == 0
    }
}

extension PlaceDeletionOptionsCell: SettingsCellDelegate {
    func backupFolder(isAvailable: Bool) {
        yesNo.isEnabled = (try? Parameters.securityScopedExportFolder()) != nil
    }
}
