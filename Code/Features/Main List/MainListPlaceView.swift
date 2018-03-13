//
//  MainListPlaceView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/13/18.
//  Copyright © 2018 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

import UIKit
import SMCoreLib

class MainListPlaceView: UIView, XibBasics {
    typealias ViewType = MainListPlaceView
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var distance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(withLocation location:Location) {
        placeName?.text = location.place?.name
        
        if location.address == nil || location.address!.count == 0 {
            address.isHidden = true
        }
        else {
            address?.text = location.address
        }
        
        switch Parameters.orderFilter {
        case .distance:
            let distanceInMiles = Location.metersToMiles(meters: location.sortingDistance)
            var distanceString = String(format: "%.2f miles", distanceInMiles)
            if location.sortingDistance == Float.greatestFiniteMagnitude {
                distanceString = "\u{221E}" // infinity.
            }
            distance?.text = "\(distanceString)"
            distance.isHidden = false
            
        case .name:
            distance?.text = nil
            distance.isHidden = true
        }
    }
}
