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
    }
    
    @IBAction func yesNoAction(_ sender: Any) {
        Parameters.removeBackupPlace.boolValue = yesNo.selectedSegmentIndex == 0
    }
}
