//
//  PlaceVC.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class PlaceVC: UIViewController {
    // Set this before presenting VC
    var place:Place!
    
    fileprivate let placeCellReuseId = "PlaceVCCell"
    @IBOutlet weak private var tableView: UITableView!
    
    fileprivate class RowView {
        let contents:UIView!
        var displayed: Bool = true
        
        init(contents: UIView) {
            self.contents = contents
        }
    }
    
    fileprivate var rowViews = [RowView]()
    fileprivate var displayedRowViews:[RowView] {
        return rowViews.filter({$0.displayed})
    }
    
    static func create() -> PlaceVC {
        return UIStoryboard(name: "Place", bundle: nil).instantiateViewController(withIdentifier: "PlaceVC") as! PlaceVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
        
        let placeNameView = PlaceNameView.create()!
        placeNameView.placeName.text = place.name
        rowViews.append(RowView(contents: placeNameView))

        let placeDetailsView = PlaceDetailsView.create()!
        placeDetailsView.setup(withPlace: place)
        rowViews.append(RowView(contents: placeDetailsView))
        
        if let locations = place.locations as? Set<Location> {
            for location in locations {
                let locationView = LocationView.create()!
                locationView.setup(withLocation: location)
                rowViews.append(RowView(contents: locationView))
            }
        }
    }
}

extension PlaceVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedRowViews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: placeCellReuseId, for: indexPath) as! PlaceVCCell
        let contents = displayedRowViews[indexPath.row].contents!
        cell.setup(withContents: contents)
        
        if indexPath.row % 2 == 0 {
            contents.backgroundColor = UIColor.rowColor1
        }
        else {
            contents.backgroundColor = UIColor.rowColor2
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let contents = displayedRowViews[indexPath.row].contents!
        return contents.frameHeight
    }
}
