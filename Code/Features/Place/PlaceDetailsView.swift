//
//  PlaceDetailsView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib

class PlaceDetailsView: UIView, XibBasics {
    typealias ViewType = PlaceDetailsView
    @IBOutlet weak var placeCategory: UITextField!
    @IBOutlet weak var generalDescription: TextView!
    @IBOutlet weak var placeLists: UITextView!
    private weak var parentVC: UIViewController!
    fileprivate var listManager:ListManager!
    
    enum TypeOfDataSource {
        case placeCategory
        case placeLists
    }
    
    fileprivate var coreDataSource:CoreDataSource!
    fileprivate var _typeOfDataSource: TypeOfDataSource!
    fileprivate var typeOfDataSource: TypeOfDataSource {
        set {
            _typeOfDataSource = newValue
        }
        get {
            return _typeOfDataSource
        }
    }
    
    fileprivate var place:Place!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: generalDescription)
        Layout.format(textBox: placeLists)
        Layout.format(textBox: placeCategory)
        generalDescription.autocapitalizationType = .sentences
    }
    
    func setup(withPlace place:Place, andParentVC parentVC: UIViewController) {
        self.parentVC = parentVC
        self.place = place
        generalDescription.text = place.generalDescription
        placeCategory.text = place.category?.name
        setupPlaceLists()
    }
    
    fileprivate func setupPlaceLists() {
        if let placeListObjs = place.lists as? Set<PlaceList> {
            // Sort them.
            var orderedPlaceListNames = [String]()
            for placeList in placeListObjs {
                orderedPlaceListNames.append(placeList.name!)
            }
            orderedPlaceListNames.sort()
            
            var placeListText = ""
            for placeList in orderedPlaceListNames {
                if placeListText.count > 0 {
                    placeListText += ", "
                }
                
                placeListText += placeList
            }
            
            placeLists.text = placeListText
        }
    }
    
    @IBAction func placeCategoryButtonAction(_ sender: Any) {
        typeOfDataSource = .placeCategory
        coreDataSource = CoreDataSource(delegate: self)
        coreDataSource.fetchData()
        
        listManager = ListManager.showFrom(parentVC: parentVC, delegate: self, title: "Place Category")
    }
    
    @IBAction func placeListsButtonAction(_ sender: Any) {
        typeOfDataSource = .placeLists
        coreDataSource = CoreDataSource(delegate: self)
        coreDataSource.fetchData()
        listManager = ListManager.showFrom(parentVC: parentVC, delegate: self, title: "Place Lists")
    }
    
    deinit {
        Log.msg("deinit")
    }
}

extension PlaceDetailsView : ListManagerDelegate {
    func listManagerNumberOfRows(_ listManager: ListManager) -> UInt {
        return coreDataSource.numberOfRows(inSection: 0)
    }
    
    func listManager(_ listManager: ListManager, itemForRow row: UInt) -> String {
        let object = coreDataSource.object(at: IndexPath(row: Int(row), section: 0))
        
        switch typeOfDataSource {
        case .placeCategory:
            return (object as! PlaceCategory).name!
            
        case .placeLists:
            return (object as! PlaceList).name!
        }
    }
    
    func listManager(_ listManager: ListManager, rowItemIsSelected row: UInt) -> Bool {
        let object = coreDataSource.object(at: IndexPath(row: Int(row), section: 0))

        switch typeOfDataSource {
        case .placeCategory:
            return place.category?.name == (object as! PlaceCategory).name
            
        case .placeLists:
            let placeListObjs = place.lists as! Set<PlaceList>
            let result = placeListObjs.filter({$0.name == (object as! PlaceList).name})
            return result.count == 1
        }
    }
    
    func listManager(_ listManager: ListManager, selectedRows: [UInt]) {
        if selectedRows.count == 0 {
            switch typeOfDataSource {
            case .placeCategory:
                place.category = nil
                placeCategory.text = ""
            
            case .placeLists:
                place.lists = NSSet()
                placeLists.text = ""
            }
        }
        else {
            switch typeOfDataSource {
            case .placeCategory:
                assert(selectedRows.count == 1)
                let category = coreDataSource.object(at: IndexPath(row: Int(selectedRows[0]), section: 0)) as! PlaceCategory
                place.category = category
                placeCategory.text = category.name

            case .placeLists:
                let placeLists = NSMutableSet()
                for selectedRow in selectedRows {
                    let placeList = coreDataSource.object(at: IndexPath(row: Int(selectedRow), section: 0)) as! PlaceList
                    placeLists.add(placeList)
                }
                place.lists = placeLists
                setupPlaceLists()
            }
        }

        place.save()
    }
    
    func listManagerSelectionsAllowed(_ listManager: ListManager) -> ListManagerSelections {
        switch typeOfDataSource {
        case .placeCategory:
            return .single
        case .placeLists:
            return .multiple
        }
    }

    func listManager(_ listManager: ListManager, deleteItemAtRow row: UInt, completion: @escaping (_ deleted: Bool)->()) {
    
        let indexPath = IndexPath(row: Int(row), section: 0)
        let object = coreDataSource.object(at: indexPath)
        var name:String?
        
        switch typeOfDataSource {
        case .placeCategory:
            if (object as! PlaceCategory).places!.count != 0 {
                name = "Place Category"
            }
        case .placeLists:
            if (object as! PlaceList).places!.count != 0 {
                name = "Place List"
            }
        }
        
        if let name = name {
            Alert.show(fromVC: listManager, withTitle: "Alert!", message: "That \(name) is in use. It can't be deleted.", okCompletion: {
                completion(false)
            })
        }
        else {
            coreDataSource.deleteObject(at: IndexPath(row: Int(row), section: 0))
            completion(true)
        }
    }
    
    func listManager(_ listManager: ListManager, insertItem: String, completion : @escaping  (_ inserted: Bool)->()) {
    
        var success:Bool
        var name:String?
        
        switch typeOfDataSource {
        case .placeCategory:
            success = PlaceCategory.getCategory(withName: insertItem) == nil
            if success {
                let newCategory = try! PlaceCategory.newObject(withName: insertItem)
                newCategory.save()
            }
            else {
                name = "Place Category"
            }
            
        case .placeLists:
            success = PlaceList.getPlaceList(withName: insertItem) == nil
            if success {
                let newPlaceList = try! PlaceList.newObject(withName: insertItem)
                newPlaceList.save()
            }
            else {
                name = "Place List"
            }
        }
    
        completion(success)
        if !success {
            Alert.show(fromVC: listManager, withTitle: "Alert!", message: "That \(name!) already exists")
        }
    }
}

extension PlaceDetailsView : CoreDataSourceDelegate {
    // This must have sort descriptor(s) because that is required by the NSFetchedResultsController, which is used internally by this class.
    func coreDataSourceFetchRequest(_ cds: CoreDataSource!) -> NSFetchRequest<NSFetchRequestResult>! {
    
        switch typeOfDataSource {
        case .placeCategory:
            return PlaceCategory.fetchRequestForAllObjects()
            
        case .placeLists:
            return PlaceList.fetchRequestForAllObjects()
        }
    }
    
    func coreDataSourceContext(_ cds: CoreDataSource!) -> NSManagedObjectContext! {
        return CoreData.sessionNamed(CoreDataExtras.sessionName).context
    }
    
    // Should return YES iff the context save was successful.
    func coreDataSourceSaveContext(_ cds: CoreDataSource!) -> Bool {
        return CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func coreDataSource(_ cds: CoreDataSource!, objectWasDeleted indexPathOfDeletedObject: IndexPath!) {
        listManager.reloadData()
    }
    
    func coreDataSource(_ cds: CoreDataSource!, objectWasInserted indexPathOfInsertedObject: IndexPath!) {
        listManager.reloadData()
    }
    
    func coreDataSource(_ cds: CoreDataSource!, objectWasUpdated indexPathOfUpdatedObject: IndexPath!) {
        listManager.reloadData()
    }
    
    // 5/20/16; Odd. This gets called when an object is updated, sometimes. It may be because the sorting key I'm using in the fetched results controller changed.
    func coreDataSource(_ cds: CoreDataSource!, objectWasMovedFrom oldIndexPath: IndexPath!, to newIndexPath: IndexPath!) {
        listManager.reloadData()
    }
}
