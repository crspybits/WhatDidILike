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
    @IBOutlet weak var generalDescription: TextView!
    @IBOutlet weak var placeLists: UITextView!
    private weak var parentVC: UIViewController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: generalDescription)
        Layout.format(textBox: placeLists)
    }
    
    func setup(withPlace place:Place, andParentVC parentVC: UIViewController) {
        self.parentVC = parentVC
        generalDescription.text = place.generalDescription
        placeCategory.text = place.category?.name
        
        if let placeListObjs = place.lists as? Set<PlaceList> {
            var placeListText = ""
            for placeList in placeListObjs {
                if placeListText.count > 0 {
                    placeListText += ", "
                }
                
                placeListText += placeList.name!
            }
            
            placeLists.text = placeListText
        }
    }
    
    @IBAction func placeCategoryButtonAction(_ sender: Any) {
        ListManager.showFrom(parentVC: parentVC, delegate: self)
    }
}

extension PlaceDetailsView : ListManagerDelegate {
    func listManagerNumberOfRows(_ listManager: ListManager) -> UInt {
        return 0
    }
    func listManager(_ listManager: ListManager, itemForRow row: UInt) -> String {
        return ""
    }
}
