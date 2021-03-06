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
import Presentr

class MainListVC: UIViewController {
    private static let converted = SMPersistItemBool(name: "MainListVC.converted", initialBoolValue: false, persistType: .userDefaults)
    
    @IBOutlet weak var tableView: UITableView!
    var coreDataSource:CoreDataSource!
    let cellReuseId = "LocationTableViewCell"
    private var indexPathOfNewPlace:IndexPath?
    private var examplePlaceView = MainListPlaceView.create()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coreDataSource = CoreDataSource(delegate: self)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        setupBarButtonItems()
        
        tableView.register(PlaceVCCell.self, forCellReuseIdentifier: cellReuseId)
    }
    
    private func setupBarButtonItems() {
        var sortImage:UIImage
        if Parameters.sortingOrderIsAscending {
            sortImage = #imageLiteral(resourceName: "sortFilterUp")
        }
        else {
            sortImage = #imageLiteral(resourceName: "sortFilterDown")
        }
    
        var rightButtons = [UIBarButtonItem]()
        let sortFilter = UIBarButtonItem(image: sortImage, style: .plain, target: self, action: #selector(sortFilterAction))
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPlace))
        
        rightButtons = [add, sortFilter]
        
        if Parameters.filterApplied {
            let filterApplied = UIBarButtonItem(image: #imageLiteral(resourceName: "filtering"), style: .plain, target: self, action: #selector(sortFilterAction))
            rightButtons += [filterApplied]
        }
        
        navigationItem.rightBarButtonItems = rightButtons
    
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editAction))
        navigationItem.leftBarButtonItem = editButton
    }
    
    @objc private func sortFilterAction() {
        SortyFilter.show(fromParentVC: self, usingDelegate: self)
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
        
        tableView.scrollToRow(at: indexPathOfNewPlace!, at: .middle, animated: true)
        TimedCallback.withDuration(0.2) {
            self.tableView.flashRow(UInt(self.indexPathOfNewPlace!.row), withDuration: TimeInterval(0.3)) {
                let placeVC = PlaceVC.create()
                placeVC.location = location
                placeVC.newPlace = true
                placeVC.delegate = self
                self.navigationController!.pushViewController(placeVC, animated: true)
                self.indexPathOfNewPlace = nil
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let coreDataSource = self.coreDataSource else {
            return
        }
        
        coreDataSource.fetchData()
        
        // In case the displayed summary info (e.g., name) changed. This doesn't get updated automagically by Core Data since the name is accessed via a relation.
        // And in case a new location was added.
        // It's hard to know which index path to reload, so this method seems best.
        tableView.reloadSections(IndexSet([0]), with: .automatic)
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
        return Int(coreDataSource?.numberOfRows(inSection: 0) ?? 0)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath) as! PlaceVCCell
        guard let coreDataSource = self.coreDataSource else {
            return cell
        }
        
        let location = coreDataSource.object(at: indexPath) as! Location
        
        let placeView = MainListPlaceView.create()!
        placeView.setup(withLocation: location)
        cell.setup(withContents: placeView)
        
        Log.msg("Location: \(String(describing: location.place?.name)); Suggestion: \(String(describing: location.place?.suggestion)); ")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let coreDataSource = self.coreDataSource else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        let placeVC = PlaceVC.create()
        placeVC.delegate = self
        let location = coreDataSource.object(at: indexPath) as! Location
        placeVC.location = location
        navigationController!.pushViewController(placeVC, animated: true)
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let coreDataSource = self.coreDataSource else {
            return
        }
        
        switch editingStyle {
        case .delete:
            let location = coreDataSource.object(at: indexPath) as! Location
            
            DeletionImpact().showWarning(for: .location(location), using: self, deletionAction: {
                location.remove()
                CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
            })
            
            tableView.setEditing(false, animated: true)
        
        default:
            assert(false)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return examplePlaceView.frameHeight
    }
}

extension MainListVC : CoreDataSourceDelegate {
    // 10/2/17; I'm fetching locations here -- becuase each place can have more than one location, and I want to get all of these locations represented here. This also means that a Place *must* have a location or I won't be able to show it here. I'm going to change the Core Data model to require each place have at least one location.
    func coreDataSourceFetchRequest(_ cds: CoreDataSource!) -> NSFetchRequest<NSFetchRequestResult>! {
        let params = Location.SortFilterParams(sortingOrder: Parameters.sortingOrder, isAscending: Parameters.sortingOrderIsAscending, tryAgainFilter: Parameters.tryAgainFilter, distanceFilter: Parameters.distanceFilter, distanceInMiles: Parameters.distanceFilterAmount)
        return Location.fetchRequestForAllObjects(sortFilter: params)
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

extension MainListVC : SortyFilterDelegate {
    func sortyFilter(reset: SortyFilter) {
        coreDataSource = nil
        setupBarButtonItems()
    }
    
    func sortyFilter(sortFilterByParameters: SortyFilter) {
        coreDataSource = CoreDataSource(delegate: self)

        // In-case the ascending/descending has changed.
        setupBarButtonItems()
        
        coreDataSource.fetchData()
        
        // Not quite sure why this is needed-- for change in alphabetic ordering.
        tableView.reloadSections([0], with: .automatic)
        
        Log.msg("sortFilterByParameters")
    }
}

extension MainListVC : PlaceVCDelegate {
    func placeNameChanged(forPlaceLocation placeLocation: Location) {
        guard let coreDataSource = self.coreDataSource else {
            return
        }
        
        // Not quite sure why both of these are needed.
        coreDataSource.fetchData()
        self.tableView.reloadSections([0], with: .none)
        
        // Need to figure out the row this location is in. And scroll to it. The only way I know how to do this is by iterating over all possible index paths.
        for row in 0...coreDataSource.numberOfRows(inSection: 0) {
            let indexPath = IndexPath(row: Int(row), section: 0)
            if let location = coreDataSource.object(at: indexPath) as? Location, location == placeLocation {
                tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                break
            }
        }
    }
}
