//
//  ListManager.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/11/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import UIKit
import SMCoreLib

enum ListManagerSelections {
    // Can go to 0 selections in either case.
    case single
    case multiple
}

protocol ListManagerDelegate {
    func listManagerSelectionsAllowed(_ listManager: ListManager) -> ListManagerSelections
    func listManagerNumberOfRows(_ listManager: ListManager) -> UInt
    func listManager(_ listManager: ListManager, itemForRow row: UInt) -> String
    func listManager(_ listManager: ListManager, rowItemIsSelected row: UInt) -> Bool
    func listManager(_ listManager: ListManager, selectedRows: [UInt])
    func listManager(_ listManager: ListManager, deleteItemAtRow row: UInt, completion : @escaping  (_ deleted: Bool)->())
    func listManager(_ listManager: ListManager, insertItem: String, completion : @escaping  (_ inserted: Bool)->())
}

class ListManager : SMModal {
    fileprivate var delegate:ListManagerDelegate!
    @IBOutlet weak var newListItem: UITextField!
    @IBOutlet weak var tableView: UITableView!
    let cellReuseId = "CellReuseId"
    
    override func viewDidLoad() {
        if let view = navigationController?.view {
            Layout.format(modal: view)
        }
        
        Layout.format(textBox: newListItem)
        
        tableView.backgroundColor = .tableViewBackground

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        navigationItem.leftBarButtonItem = doneButton
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editAction))
        navigationItem.rightBarButtonItem = editButton
        
        newListItem.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
    
        newListItem.autocapitalizationType = .words
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let firstSelectedItem = indexPathForFirstSelectedItem() {
            tableView.scrollToRow(at: firstSelectedItem, at: .middle, animated: true)
        }
    }
    
    @objc private func doneAction() {
        close()
    }
    
    @objc private func editAction() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    @discardableResult
    static func showFrom(parentVC: UIViewController, delegate: ListManagerDelegate, title: String) -> ListManager {
        let listManager = ListManager(nibName: "ListManager", bundle: nil)
        listManager.modalSize = CGSize(width: parentVC.view.frameWidth*0.9, height: parentVC.view.frameHeight*0.9)
        listManager.modalParentVC = parentVC
        listManager.delegate = delegate
        listManager.title = title
        listManager.show()
                
        return listManager
    }
    
    private func indexPathForFirstSelectedItem() -> IndexPath? {
        for itemNumber in 0..<delegate.listManagerNumberOfRows(self) {
            if delegate.listManager(self, rowItemIsSelected: itemNumber) {
                return IndexPath(row: Int(itemNumber), section: 0)
            }
        }
        
        return nil
    }
    
    private func indexPathForItem(listItem: String) -> IndexPath? {
        for itemNumber in 0..<delegate.listManagerNumberOfRows(self) {
            if delegate.listManager(self, itemForRow: itemNumber) == listItem {
                return IndexPath(row: Int(itemNumber), section: 0)
            }
        }
        
        return nil
    }
    
    @IBAction func newListItemAction(_ sender: Any) {
        let whiteSpace = CharacterSet.whitespacesAndNewlines
        newListItem.text = newListItem.text!.trimmingCharacters(in: whiteSpace)
        if newListItem.text!.count > 0 {
            let newItem = newListItem.text!
            delegate.listManager(self, insertItem: newItem) {[unowned self] success in
                if success {
                    self.newListItem.text = ""
                    self.newListItem.resignFirstResponder()
                    let indexPath = self.indexPathForItem(listItem: newItem)!
                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                    
                    // To wait for scroll to finish, and becuase otherwise I don't see the flashing.
                    TimedCallback.withDuration(0.5) {
                        self.tableView.flashRow(UInt(indexPath.row), withDuration: 1)
                    }
                }
            }
        }
    }
    
    func reloadData() {
        tableView.reloadData()
    }
}

extension ListManager : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ListManager : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(delegate.listManagerNumberOfRows(self))
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        cell.textLabel?.text = delegate.listManager(self, itemForRow: UInt(indexPath.row))
        let selected = delegate.listManager(self, rowItemIsSelected: UInt(indexPath.row))
        cell.accessoryType = selected ? .checkmark : .none
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            delegate.listManager(self, deleteItemAtRow: UInt(indexPath.row)) { success in
                if success {
                    // The set editing doesn't work without this.
                    DispatchQueue.main.async {
                        tableView.setEditing(false, animated: true)
                    }
                }
            }
            
        default:
            assert(false)
        }
    }
    
    private func indexPathsForSelectedItems() -> [IndexPath] {
        var result = [IndexPath]()
        
        for itemNumber in 0..<delegate.listManagerNumberOfRows(self) {
            if delegate.listManager(self, rowItemIsSelected: itemNumber) {
                result += [IndexPath(row: Int(itemNumber), section: 0)]
            }
        }
        
        return result
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var selectedItems = indexPathsForSelectedItems()
        let selectionType = delegate.listManagerSelectionsAllowed(self)
        
        // See if this is a selection or a deselection; cheat and just use the checkmark state of our row!
        let cell = tableView.cellForRow(at: indexPath)!
        if cell.accessoryType == .checkmark {
            // Deselection
            selectedItems = selectedItems.filter({$0.row != indexPath.row})
        }
        else {
            // Selection
            selectedItems += [indexPath]
        }
        
        switch selectionType {
        case .single:
            // Can have only a single item selected-- so if there is another selected, remove it.
            if selectedItems.count > 1 {
                selectedItems = selectedItems.filter({$0.row == indexPath.row})
            }

        case .multiple:
            // Nothing else to do.
            break
        }
        
        delegate.listManager(self, selectedRows: selectedItems.map({UInt($0.row)}))
        reloadData()
    }
}
