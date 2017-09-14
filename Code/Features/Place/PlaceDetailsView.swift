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
    fileprivate var dataSource:CoreDataSource!
    fileprivate var place:Place!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: generalDescription)
        Layout.format(textBox: placeLists)
    }
    
    func setup(withPlace place:Place, andParentVC parentVC: UIViewController) {
        self.parentVC = parentVC
        self.place = place
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
        dataSource = CoreDataSource(delegate: self)
        dataSource.fetchData()
        listManager = ListManager.showFrom(parentVC: parentVC, delegate: self)
        listManager.title = "Place Category"
    }
}

extension PlaceDetailsView : ListManagerDelegate {
    func listManagerNumberOfRows(_ listManager: ListManager) -> UInt {
        return dataSource.numberOfRows(inSection: 0)
    }
    
    func listManager(_ listManager: ListManager, itemForRow row: UInt) -> String {
        let object = dataSource.object(at: IndexPath(row: Int(row), section: 0)) as! PlaceCategory
        return object.name!
    }
    
    func listManager(_ listManager: ListManager, rowItemIsSelected row: UInt) -> Bool {
        let object = dataSource.object(at: IndexPath(row: Int(row), section: 0)) as! PlaceCategory
        return place.category?.name == object.name
        
        /*
        if let placeListObjs = place.lists as? Set<PlaceList> {
            let result = placeListObjs.filter({$0.name == object.name})
            return result.count == 1
        }*/
    }
    
    func listManager(_ listManager: ListManager, selectedRows: [UInt]) {
        if selectedRows.count == 0 {
            place.category = nil
            placeCategory.text = ""
            place.save()
        }
        else if selectedRows.count == 1 {
            let category = dataSource.object(at: IndexPath(row: Int(selectedRows[0]), section: 0)) as! PlaceCategory
            place.category = category
            placeCategory.text = category.name
            place.save()
        }
        else {
            assert(false)
        }
    }
    
    func listManagerSelectionsAllowed(_ listManager: ListManager) -> ListManagerSelections {
        return .single
    }

    func listManager(_ listManager: ListManager, deleteItemAtRow row: UInt, completion: @escaping (_ deleted: Bool)->()) {
        let indexPath = IndexPath(row: Int(row), section: 0)
        let object = dataSource.object(at: indexPath) as! PlaceCategory
        
        // Don't allow deletion if this PlaceCategory is in use.
        if object.places!.count == 0 {
            dataSource.deleteObject(at: IndexPath(row: Int(row), section: 0))
            completion(true)
        }
        else {
            Alert.show(fromVC: listManager, withTitle: "Alert!", message: "That PlaceCategory is in use. It can't be deleted.", okCompletion: {
                completion(false)
            })
        }
    }
    
    func listManager(_ listManager: ListManager, insertItem: String, completion : @escaping  (_ inserted: Bool)->()) {
        guard PlaceCategory.getCategory(withName: insertItem) == nil else {
            completion(false)
            Alert.show(fromVC: listManager, withTitle: "Alert!", message: "That PlaceCategory already exists")
            return
        }
        
        let newCategory = try! PlaceCategory.newObject(withName: insertItem)
        newCategory.save()
        completion(true)
    }
}

extension PlaceDetailsView : CoreDataSourceDelegate {
    // This must have sort descriptor(s) because that is required by the NSFetchedResultsController, which is used internally by this class.
    func coreDataSourceFetchRequest(_ cds: CoreDataSource!) -> NSFetchRequest<NSFetchRequestResult>! {
        return PlaceCategory.fetchRequestForAllObjects()
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
