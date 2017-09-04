//
//  PlaceDetailsView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class PlaceDetailsView: UIView, XibBasics {
    typealias ViewType = PlaceDetailsView
    @IBOutlet weak var placeCategory: UITextField!
    @IBOutlet weak var generalDescription: UITextView!
    @IBOutlet weak var placeLists: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let descrLayer = generalDescription.layer
        descrLayer.borderColor = UIColor.textBoxLightGray.cgColor
        descrLayer.borderWidth = 1.0
        descrLayer.cornerRadius = 5.0
        
        let placeListsLayer = placeLists.layer
        placeListsLayer.borderColor = UIColor.textBoxLightGray.cgColor
        placeListsLayer.borderWidth = 1.0
        placeListsLayer.cornerRadius = 5.0
    }
    
    func setup(withPlace place:Place) {
        generalDescription.text = place.generalDescription
        placeCategory.text = place.category?.name
        
        if let placeListObjs = place.lists as? Set<PlaceList> {
            var placeListText = ""
            for placeList in placeListObjs {
                if placeListText.count > 0 {
                    placeListText += "\n"
                }
                
                placeListText += placeList.name!
            }
            
            placeLists.text = placeListText
        }
    }
}
