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

class RowView {
    let contents:UIView!
    var displayed: Bool = true
    
    init(contents: UIView) {
        self.contents = contents
    }
}

protocol PlaceVCDelegate {
    // Reference a location here and not a place because a place can have multiple locations, and if we're sorting by location on the main screen, we can't scroll to both of them.
    func placeNameChanged(forPlaceLocation: Location)
}

class PlaceVC: UIViewController {
    // Set this before presenting VC
    var location:Location!
    
    var delegate:PlaceVCDelegate?
    
    // If you are creating a new place, set this to true before presenting VC.
    var newPlace = false
    
    private var place:Place!
    private var titleLabel = UILabel()
    
    fileprivate let placeCellReuseId = "PlaceVCCell"
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak private var tableViewBottom: NSLayoutConstraint!
    private var animatingEarthImageView:FLAnimatedImageView!
    private var checkIn: PlaceCheckIn!

    fileprivate var rowViews = [RowView]()
    fileprivate var displayedRowViews:[RowView] {
        return rowViews.filter({$0.displayed})
    }
    
    static func create() -> PlaceVC {
        return UIStoryboard(name: "Place", bundle: nil).instantiateViewController(withIdentifier: "PlaceVC") as! PlaceVC
    }
    
    private func setTitle() {
        titleLabel.text = place.name
        titleLabel.sizeToFit()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        place = location.place
        
        checkIn = PlaceCheckIn(place, parent: self)
        checkIn.start()
        
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        navigationItem.titleView = titleLabel
        setTitle()
        
        let (imageView, barButton) = GPSExtras.spinner()
        navigationItem.rightBarButtonItem = barButton
        animatingEarthImageView = imageView
        
        let placeNameView = PlaceNameView.create()!
        placeNameView.placeName.text = place.name
        placeNameView.placeName.save = {[unowned self] update in
            self.place.name = update
            self.setTitle()
            self.place.save()
            self.delegate?.placeNameChanged(forPlaceLocation: self.location)
        }
        rowViews.append(RowView(contents: placeNameView))

        let placeDetailsView = PlaceDetailsView.create()!
        placeDetailsView.setup(withPlace: place, andParentVC: self)
        placeDetailsView.generalDescription.save = {[unowned self] update in
            self.place.generalDescription = update
            self.place.save()
        }
        rowViews.append(RowView(contents: placeDetailsView))
        
        let newLocation = NewObject.create()!
        newLocation.setButton(name: "New Location")
        rowViews.append(RowView(contents: newLocation))

        newLocation.new = {[unowned newLocation, unowned self] in
            guard let location = try? Location.newObject() else {
                return
            }
            
            self.place.addToLocations(location)
            self.place.save()
            
            // Need to add a RowView immediately after this `NewLocation` header.
            // 1) Figure out where the newLocation instance is in the rowViews
            // 2) Add in the new location
            
            let newLocationIndex =
                self.rowViews.index(where: {$0.contents == newLocation})!
            self.insertLocation(location, startingAtRowViewIndex: newLocationIndex+1, newLocation: true)
            
            self.tableView.reloadData()
        }
        
        if let locations = place.locations as? Set<Location> {
            for location in locations {
                let imageFileNames = (Array(location.images!) as! [Image]).map({$0.fileName!})
                Log.msg("location imageFileNames: \(imageFileNames)")
                
                let markLocation = location == self.location
                insertLocation(location, startingAtRowViewIndex: rowViews.endIndex, markLocation: markLocation, newLocation: newPlace)
            }
        }
        
        let newItem = NewObject.create()!
        newItem.setButton(name: "New Menu Item")
        rowViews.append(RowView(contents: newItem))
        
        newItem.new = {[unowned newItem, unowned self] in
            guard let item = try? Item.newObject() else {
                return
            }

            var singleComment:Comment!
            if Parameters.commentStyle == .single {
                singleComment = try? Comment.newObject()
                guard singleComment != nil else {
                    item.remove()
                    return
                }
            }
            
            let items = NSMutableOrderedSet(orderedSet: self.place.items!)
            items.insert(item, at: 0)
            self.place.items = items
            
            // Creating a new item. If our comment style is single, then we'll also create the single comment for that item.
            if Parameters.commentStyle == .single {
                item.addToComments(singleComment)
            }
            
            self.place.save()
            
            // Insert this right below the new item header-- newer items float to the top.
            let newItemIndex = self.rowViews.index(where: {$0.contents == newItem})!
            let newItemView = self.insertItem(item, atRowViewIndex: newItemIndex+1)
            
            if Parameters.commentStyle == .single {
                let newCommentView = self.insertComment(singleComment, ownerItemNameView: newItemView, atRowViewIndex: newItemIndex+2)
                newItemView.commentViewsForItem.append(newCommentView)
            }
            
            self.tableView.reloadData()
        }
        
        if let items = place.items {
            for item in items {
                let item = item as! Item
                let itemNameView = insertItem(item, atRowViewIndex: rowViews.endIndex)
                
                if let comments = item.comments {
                    Log.msg("comments.count: \(comments.count)")
                    for comment in comments {
                        let comment = comment as! Comment
                        
                        let imageFileNames = (Array(comment.images!) as! [Image]).map({$0.fileName!})
                        Log.msg("itemName: \(String(describing: item.name)); imageFileNames: \(imageFileNames)")
                        
                        let commentRowView = insertComment(comment, ownerItemNameView: itemNameView, atRowViewIndex: rowViews.endIndex)
                        itemNameView.commentViewsForItem.append(commentRowView)
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
        
        let images = DeletionImpact().imagesAssociatedWith(location: location!)
        let imageNames = images.map({$0.fileName!})
        Log.msg("imageNames: \(imageNames)")
    }
    
    deinit {
        // Log.msg("deinit")
    }
    
    @discardableResult
    private func insertComment(_ comment: Comment, ownerItemNameView: ItemNameView, atRowViewIndex index: Int, displayed: Bool = false) -> RowView {
    
        let commentView = CommentView.create()!
        commentView.setup(withComment: comment, andParentVC: self)
        
        let commentRowView = RowView(contents: commentView)
        commentRowView.displayed = displayed
        rowViews.insert(commentRowView, at: index)
        
        commentView.comment.save = {update in
            comment.comment = update
            comment.save()
        }
        
        commentView.removeComment = {[unowned self, unowned commentView, unowned ownerItemNameView] in
            DeletionImpact().showWarning(for: .comment(comment), using: self, deletionAction: {
            
                comment.remove()
                CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
                
                let commentViewIndex = self.rowViews.index(where: {$0.contents == commentView})!
                self.rowViews.remove(at: commentViewIndex)
                
                let commentRowViewIndex = ownerItemNameView.commentViewsForItem.index(where: {$0.contents == commentView})!
                ownerItemNameView.commentViewsForItem.remove(at: commentRowViewIndex)
                
                if ownerItemNameView.commentViewsForItem.count == 0 {
                    ownerItemNameView.showHideState = .closed
                }
                
                self.tableView.reloadData()
            })
        }
        
        return commentRowView
    }
    
    @discardableResult
    private func insertItem(_ item: Item, atRowViewIndex index: Int) -> ItemNameView {
        let itemNameView = ItemNameView.create()!
        itemNameView.itemName.text = item.name
        itemNameView.itemName.save = { update in
            item.name = update
            item.save()
        }
        rowViews.insert(RowView(contents: itemNameView), at: index)
        
        itemNameView.delete = {[unowned itemNameView, unowned self] in
            DeletionImpact().showWarning(for: .item(item), using: self, deletionAction: { [unowned self] in
            
                item.remove()
                CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
                
                let itemViewIndex = self.rowViews.index(where: {$0.contents == itemNameView})!
                self.rowViews.remove(at: itemViewIndex)
                
                self.tableView.reloadData()
            })
        }
        
        itemNameView.addComment = {[unowned itemNameView, unowned self] in
            guard let comment = try? Comment.newObject() else {
                return
            }
            
            let comments = NSMutableOrderedSet(orderedSet: item.comments!)
            comments.insert(comment, at: 0)
            item.comments = comments
            item.save()
            
            let newCommentIndex = self.rowViews.index(where: {$0.contents == itemNameView})!
            let commentRowView = self.insertComment(comment, ownerItemNameView: itemNameView, atRowViewIndex: newCommentIndex+1, displayed: true)
            itemNameView.commentViewsForItem.append(commentRowView)
            
            if itemNameView.showHideState == .closed {
                itemNameView.showHideState = .open
            }
            
            self.tableView.reloadData()
        }
        
        itemNameView.showHide = { [unowned self, unowned itemNameView] state in
            if itemNameView.commentViewsForItem.count > 0 {
                for commentView in itemNameView.commentViewsForItem {
                    commentView.displayed = state == .open
                }
                Log.msg("commentViewsForItem.count: \(itemNameView.commentViewsForItem.count)")
                self.tableView.reloadData()
            }
        }
        
        return itemNameView
    }
    
    private func insertLocation(_ location: Location, startingAtRowViewIndex index: Int, markLocation:Bool = false, newLocation: Bool = false) {
    
        let locationHeader = LocationHeader.create()!
        locationHeader.setup(withLocation: location)
        
        if markLocation {
            // This is the "active" location for the place. Mark it differently.
            // Using a textBox format because I want the active location to look like a text box.
            Layout.format(textBox: locationHeader)
        }
        rowViews.insert(RowView(contents: locationHeader), at: index)

        let locationView = LocationView.create()!
        locationView.setup(withLocation: location, place: place, viewController: self)
        
        locationView.addressWasUpdated = {
            locationHeader.setup(withLocation: location)
        }
        
        locationView.delegate = self
        let locationViewRow = RowView(contents: locationView)
        locationViewRow.displayed = false
        rowViews.insert(locationViewRow, at: index+1)
        
        if newLocation {
            locationView.establishCurrentCoordinates()
        }

        locationHeader.showHide = {[unowned self] state in
            locationViewRow.displayed = state == .open
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
        cell.layoutIfNeeded()
        
        return cell
    }
    
    private func rowHeight(_ row:Int) -> CGFloat {
        let contents = displayedRowViews[row].contents!
        let rowHeight = contents.frameHeight        
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight(indexPath.row)
    }
}

extension PlaceVC : GPSDelegate {
    func startedUsingGPS(_ obj: Any) {
        animatingEarthImageView.isHidden = false
    }
    
    func stoppedUsingGPS(_ obj: Any) {
        animatingEarthImageView.isHidden = true
    }
}
