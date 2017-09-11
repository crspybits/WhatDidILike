//
//  PlaceVC.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib

class PlaceVC: UIViewController {
    // Set this before presenting VC
    var place:Place!
    
    fileprivate let placeCellReuseId = "PlaceVCCell"
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var tableViewBottom: NSLayoutConstraint!
    
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
    
    private func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let placeNameView = PlaceNameView.create()!
        placeNameView.placeName.text = place.name
        placeNameView.placeName.save = {[unowned self] update in
            self.place.name = update
            self.save()
        }
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
        
        if let items = place.items {
            for item in items {
                let item = item as! Item
                let itemNameView = ItemNameView.create()!
                itemNameView.itemName.text = item.name
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollingSetup(selector: #selector(keyboardWillChangeFrame))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scrollingTearDown()
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
