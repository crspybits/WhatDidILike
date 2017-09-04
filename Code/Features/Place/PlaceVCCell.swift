//
//  PlaceVCCell.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib

class PlaceVCCell: UITableViewCell {
    private var contents:UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup(withContents contents: UIView) {
        self.contents?.removeFromSuperview()
        self.contents = contents
        contents.frameWidth = contentView.frameWidth
        contentView.frameHeight = contents.frameHeight
        contentView.addSubview(contents)
    }
}
