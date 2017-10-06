//
//  PlaceVC.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib
import FLAnimatedImage

class PlaceVC: UIViewController {
    // Set this before presenting VC
    var location:Location!
    
    private var place:Place!
    
    fileprivate let placeCellReuseId = "PlaceVCCell"
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var tableViewBottom: NSLayoutConstraint!
    private var animatingEarthImageView:FLAnimatedImageView!
    
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
        
        place = location.place
        
        let gifURL = Bundle.main.url(forResource: "rotatingEarth", withExtension: "gif")
        let gifData = try! Data(contentsOf: gifURL!)
        let image = FLAnimatedImage(animatedGIFData: gifData)
        animatingEarthImageView = FLAnimatedImageView()
        animatingEarthImageView.animatedImage = image
        animatingEarthImageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        let earthBarButtonItem = UIBarButtonItem(customView: animatingEarthImageView)
        animatingEarthImageView.isHidden = true
        navigationItem.rightBarButtonItem = earthBarButtonItem
        
        let placeNameView = PlaceNameView.create()!
        placeNameView.placeName.text = place.name
        placeNameView.placeName.save = {[unowned self] update in
            self.place.name = update
            self.place.save()
        }
        rowViews.append(RowView(contents: placeNameView))

        let placeDetailsView = PlaceDetailsView.create()!
        placeDetailsView.setup(withPlace: place, andParentVC: self)
        placeDetailsView.generalDescription.save = {[unowned self] update in
            self.place.generalDescription = update
            self.place.save()
        }
        rowViews.append(RowView(contents: placeDetailsView))
        
        let newLocation = NewLocation.create()!
        rowViews.append(RowView(contents: newLocation))

        newLocation.newLocation = {
            let location = Location.newObject()
            self.place.addToLocations(location)
            self.place.save()
            
            // Need to add a RowView immediately after this `NewLocation` header.
            // 1) Figure out where the newLocation instance is in the rowViews
            // 2) Add in the new location
            
            let newLocationIndex =
                self.rowViews.index(where: {$0.contents == newLocation})!
            self.insertLocation(location, startingAtRowViewIndex: newLocationIndex+1)
            self.tableView.reloadData()
        }
        
        if let locations = place.locations as? Set<Location> {
            for location in locations {
                let markLocation = location == self.location
                insertLocation(location, startingAtRowViewIndex: rowViews.endIndex, markLocation: markLocation)
            }
        }
        
        if let items = place.items {
            for item in items {
                let item = item as! Item
                let itemNameView = ItemNameView.create()!
                itemNameView.itemName.text = item.name
                itemNameView.itemName.save = { update in
                    item.name = update
                    item.save()
                }
                rowViews.append(RowView(contents: itemNameView))
                
                var commentViewsForItem = [RowView]()
                itemNameView.showHide = { [unowned self] in
                    if commentViewsForItem.count > 0 {
                        let showHideState = !commentViewsForItem[0].displayed
                        for commentView in commentViewsForItem {
                            commentView.displayed = showHideState
                        }
                        Log.msg("commentViewsForItem.count: \(commentViewsForItem.count)")
                        self.tableView.reloadData()
                    }
                }
                
                if let comments = item.comments {
                    Log.msg("comments.count: \(comments.count)")
                    for comment in comments {
                        let comment = comment as! Comment
                        let commentView = CommentView.create()!
                        commentView.setup(withComment: comment)
                        commentView.comment.save = {update in
                            comment.comment = update
                            comment.save()
                        }
                        let commentRowView = RowView(contents: commentView)
                        commentRowView.displayed = false
                        rowViews.append(commentRowView)
                        commentViewsForItem.append(commentRowView)
                    }
                }
            }
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        
        let cellNib = UINib(nibName: "PlaceVCCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: placeCellReuseId)
    }
    
    private func insertLocation(_ location: Location, startingAtRowViewIndex index: Int, markLocation:Bool = false) {
        let locationHeader = LocationHeader.create()!
        locationHeader.setup(withLocation: location)
        if markLocation {
            // Do something fancier...
            locationHeader.debugBlackBorder = true
        }
        rowViews.insert(RowView(contents: locationHeader), at: index)

        let locationView = LocationView.create()!
        locationView.setup(withLocation: location, place: place, viewController: self)
        locationView.address.save = { update in
            location.address = update
            location.save()
        }
        locationView.specificDescription.save = { update in
            location.specificDescription = update
            location.save()
        }
        locationView.delegate = self
        let locationViewRow = RowView(contents: locationView)
        locationViewRow.displayed = false
        rowViews.insert(locationViewRow, at: index+1)

        locationHeader.showHide = {
            locationViewRow.displayed = !locationViewRow.displayed
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollingSetup(selector: #selector(keyboardWillChangeFrame))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scrollingTearDown()
        
        for rowView in rowViews {
            // In case, geocoding is occuring or LocationView is using GPS.
            if let locationView = rowView.contents as? LocationView {
                locationView.close()
            }
        }
    }
    
    @objc func keyboardWillChangeFrame(notification:NSNotification) {
        guard let firstResponder = UIResponder.currentFirstResponder() as? UIView else {
            Log.error("No first responder view!!!")
            return
        }

        scrollingKeyboardWillChangeFrame(notification: notification, scrollViewBottom: tableViewBottom, scrollView: tableView, showView: firstResponder)
    }
}

extension PlaceVC : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let contents = displayedRowViews[indexPath.row].contents!
        Log.msg("cell.contents.frame: \(contents.frame); superview: \(contents.superview!.frame); contents.isHidden: \(contents.isHidden);  superview.isHidden: \(contents.superview!.isHidden)")
        Log.msg("cell.contentView.subviews.count: \(cell.contentView.subviews.count)")
    }
    
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
        
        cell.layoutIfNeeded()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let contents = displayedRowViews[indexPath.row].contents!
        return contents.frameHeight
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let contents = displayedRowViews[indexPath.row].contents!
        return contents.frameHeight
    }
}

extension PlaceVC : LocationViewDelegate {
    func locationViewStartedUsingGPS(_ lv: LocationView) {
        animatingEarthImageView.isHidden = false
    }
    
    func locationViewStoppedUsingGPS(_ lv: LocationView) {
        animatingEarthImageView.isHidden = true
    }
}
