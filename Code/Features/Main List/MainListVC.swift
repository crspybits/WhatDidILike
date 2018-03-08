//
//  MainListVC.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib
import M13ProgressSuite

class MainListVC: UIViewController {
    private static let converted = SMPersistItemBool(name: "MainListVC.converted", initialBoolValue: false, persistType: .userDefaults)
    
    @IBOutlet weak var tableView: UITableView!
    var coreDataSource:CoreDataSource!
    let cellReuseId = "LocationTableViewCell"
    private var showDetailsForIndexPath:IndexPath?
    private var indexPathOfNewPlace:IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        coreDataSource = CoreDataSource(delegate: self)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setupBarButtonItems()
    }
    
    private func setupBarButtonItems() {
        var sortImage:UIImage
        if Parameters.orderFilter.isAscending {
            sortImage = #imageLiteral(resourceName: "sortFilterDown")
        }
        else {
            sortImage = #imageLiteral(resourceName: "sortFilterUp")
        }
    
        let sortFilter = UIBarButtonItem(image: sortImage, style: .plain, target: self, action: #selector(sortFilterAction))
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPlace))
        navigationItem.rightBarButtonItems = [add, sortFilter]
    
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editAction))
        navigationItem.leftBarButtonItem = editButton
    }
    
    @objc private func sortFilterAction() {
        let sortFilter = SortFilter.showFrom(parentVC: self)
        sortFilter.delegate = self
    }
    
    @objc private func editAction() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    @objc private func addNewPlace() {
        let newPlace = Place.newObject()
        newPlace.name = "New Place"
        
        // Each place must have at least one location.
        let location = Location.newObject()
        newPlace.addToLocations(location)
        
        newPlace.save()

        /* Need to:
            (a) figure out the index path of this new object,
            (b) scroll to that row, and
            (c) show this Place in the PlaceVC.
        */
        
        // The `objectWasInserted` delegate method gets called before `save` returns-- so we'll have the index path of the new object.
        
        /* TODO: When we get back from the PlaceVC
            a) scroll to the newly created place,
            b) refresh it's name-- this may reposition it.
            NEED to do this for just regular editing too.
        */
        tableView.scrollToRow(at: indexPathOfNewPlace!, at: .middle, animated: true)
        TimedCallback.withDuration(0.2) {
            self.tableView.flashRow(UInt(self.indexPathOfNewPlace!.row), withDuration: TimeInterval(0.3)) {
                let placeVC = PlaceVC.create()
                placeVC.location = location
                placeVC.newPlace = true
                self.showDetailsForIndexPath = self.indexPathOfNewPlace
                self.navigationController!.pushViewController(placeVC, animated: true)
                self.indexPathOfNewPlace = nil
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        coreDataSource.fetchData()
        
        if let showDetailsForIndexPath = showDetailsForIndexPath {
            // Just in case the displayed summary info (e.g., name) changed. This doesn't get updated automagically by Core Data since the name is accessed via a relation.
            tableView.reloadRows(at: [showDetailsForIndexPath], with: .automatic)
            self.showDetailsForIndexPath = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !MainListVC.converted.boolValue {
            // Various `asyncAfter` calls to get conversion progress displayed in the UI.
            if let conversionNeeded = ConvertFromV1(viewController: self) {
                let prompt = CommentPromptVC.createWith(parentVC: self)
                prompt.single = {[unowned prompt] in
                    MainListVC.converted.boolValue = true
                    Parameters.commentStyle = .single
                    prompt.close()
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                        conversionNeeded.doIt(commentStyle: .single)
                    }
                }
                prompt.multiple = {[unowned prompt] in
                    MainListVC.converted.boolValue = true
                    Parameters.commentStyle = .multiple
                    prompt.close()
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                        conversionNeeded.doIt(commentStyle: .multiple)
                    }
                }
                prompt.show()
            }
            else {
                MainListVC.converted.boolValue = true
            }
        }
    }
}

extension MainListVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(coreDataSource.numberOfRows(inSection: 0))
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        let location = self.coreDataSource.object(at: indexPath) as! Location
        cell.textLabel?.text = location.place?.name
        
        switch Parameters.orderFilter {
        case .distance:
            let distanceInMiles = Location.metersToMiles(meters: location.sortingDistance)
            var distanceString = String(format: "%.2f miles", distanceInMiles)
            if location.sortingDistance == Float.greatestFiniteMagnitude {
                distanceString = "\u{221E}" // infinity.
            }
            cell.detailTextLabel?.text = "\(distanceString)"
            
        case .name:
            cell.detailTextLabel?.text = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let placeVC = PlaceVC.create()
        let location = self.coreDataSource.object(at: indexPath) as! Location
        placeVC.location = location
        showDetailsForIndexPath = indexPath
        navigationController!.pushViewController(placeVC, animated: true)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let location = self.coreDataSource.object(at: indexPath) as! Location
            
            DeletionImpact().showWarning(for: .location(location), using: self, deletionAction: {
                location.remove()
                CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
            })
            
            tableView.setEditing(false, animated: true)
        
        default:
            assert(false)
        }
    }
}

extension MainListVC : CoreDataSourceDelegate {
    // 10/2/17; I'm fetching locations here -- becuase each place can have more than one location, and I want to get all of these locations represented here. This also means that a Place *must* have a location or I won't be able to show it here. I'm going to change the Core Data model to require each place have at least one location.
    func coreDataSourceFetchRequest(_ cds: CoreDataSource!) -> NSFetchRequest<NSFetchRequestResult>! {
        return Location.fetchRequestForAllObjects(sortingOrder: Parameters.orderFilter)
    }
    
    func coreDataSourceContext(_ cds: CoreDataSource!) -> NSManagedObjectContext! {
        return CoreData.sessionNamed(CoreDataExtras.sessionName).context
    }
    
    // Should return YES iff the context save was successful.
    func coreDataSourceSaveContext(_ cds: CoreDataSource!) -> Bool {
        return CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func coreDataSource(_ cds: CoreDataSource!, objectWasDeleted indexPathOfDeletedObject: IndexPath!) {
        tableView.deleteRows(at: [indexPathOfDeletedObject], with: .automatic)
    }
    
    func coreDataSource(_ cds: CoreDataSource!, objectWasInserted indexPathOfInsertedObject: IndexPath!) {
        indexPathOfNewPlace = indexPathOfInsertedObject
        tableView.reloadData()
    }
    
    func coreDataSource(_ cds: CoreDataSource!, objectWasUpdated indexPathOfUpdatedObject: IndexPath!) {
        tableView.reloadData()
    }
    
    // 5/20/16; Odd. This gets called when an object is updated, sometimes. It may be because the sorting key I'm using in the fetched results controller changed.
    func coreDataSource(_ cds: CoreDataSource!, objectWasMovedFrom oldIndexPath: IndexPath!, to newIndexPath: IndexPath!) {
        tableView.reloadData()
    }
}

extension MainListVC : SortFilterDelegate {
    func sortFilter(_ sortFilterByParameters: SortFilter) {
        // In-case the ascending/descending has changed.
        self.setupBarButtonItems()
        
        self.coreDataSource.fetchData()
        
        // Not quite sure why this is needed-- for change in alphabetic ordering.
        self.tableView.reloadSections([0], with: .automatic)
    }
}
