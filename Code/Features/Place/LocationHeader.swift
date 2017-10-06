//
//  LocationHeader.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/5/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

class LocationHeader : UIView, XibBasics {
    typealias ViewType = LocationHeader
    @IBOutlet weak var address: UILabel!
    var showHide:(()->())?
    private var location:Location!
    
    @IBAction func showHideAction(_ sender: Any) {
        showHide?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(withLocation location: Location) {
        self.location = location
        address.text = location.address
    }
}
