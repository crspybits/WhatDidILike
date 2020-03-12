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
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private let contentsTag = 18
    
    func setup(withContents contents: UIView) {
        contents.tag = contentsTag
        
        for view in contentView.subviews {
            if view.tag == contentsTag {
                view.removeFromSuperview()
            }
        }
        
        contents.frameWidth = contentView.frameWidth
        contentView.addSubview(contents)
        
        // Log.msg("contents.frame: \(contents.frame)")
    }
    
    deinit {
        // Log.msg("deinit")
    }
}
