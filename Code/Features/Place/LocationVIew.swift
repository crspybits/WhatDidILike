//
//  LocationView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import MapKit

class LocationView: UIView, XibBasics {
    typealias ViewType = LocationView
    @IBOutlet weak var address: UITextView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var gpsLocation: UISegmentedControl!
    @IBOutlet weak var specificDescription: UITextView!
    @IBOutlet weak var ratingContainer: UIView!
    let rating = RatingView.create()!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: address)
        Layout.format(textBox: specificDescription)
        
        rating.frameWidth = ratingContainer.frameWidth
        ratingContainer.addSubview(rating)
    }
    
    func setup(withLocation location: Location) {
        address.text = location.address
    }
}
