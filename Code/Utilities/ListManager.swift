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
    func listManager(_ listManager: ListManager, selectionChangedFor row: UInt, isSelected: Bool)
    func listManager(_ listManager: ListManager, deleteItemAtRow row: UInt, completion : @escaping  (_ deleted: Bool)->())
    func listManager(_ listManager: ListManager, insertItem: String, completion : @escaping  (_ inserted: Bool)->())
}

class ListManager : SMModal {
    fileprivate var delegate:ListManagerDelegate!
    @IBOutlet weak var newListItem: UITextField!
    @IBOutlet weak var tableView: UITableView!
    let cellReuseId = "CellReuseId"
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        navigationItem.leftBarButtonItem = doneButton
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editAction))
        navigationItem.rightBarButtonItem = editButton
        
        newListItem.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
    }
    
    @objc private func doneAction() {
        close()
    }
    
    @objc private func editAction() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    static func showFrom(parentVC: UIViewController, delegate: ListManagerDelegate) -> ListManager {
        let listManager = ListManager(nibName: "ListManager", bundle: nil)
        listManager.modalSize = CGSize(width: parentVC.view.frameWidth*0.9, height: parentVC.view.frameHeight*0.9)
        listManager.modalParentVC = parentVC
        listManager.delegate = delegate
        listManager.show()
        
        return listManager
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
        
        let row = UInt(indexPath.row)
        let selected = delegate.listManager(self, rowItemIsSelected: row)
        let selectionType = delegate.listManagerSelectionsAllowed(self)
        delegate.listManager(self, selectionChangedFor: row, isSelected: !selected)
        
        // To change checkmark state.
        tableView.reloadRows(at: [indexPath], with: .automatic)
        
        switch selectionType {
        case .single:
            // Must have only a single item selected-- so if there is another selected, turn it off.
            let selectedItems = indexPathsForSelectedItems()
            if selectedItems.count > 1 {
                let others = selectedItems.filter({$0.row != indexPath.row})
                _ = others.map({ indexPath in
                    delegate.listManager(self, selectionChangedFor: UInt(indexPath.row), isSelected: false)
                })
                tableView.reloadRows(at: others, with: .automatic)
            }
        case .multiple:
            // Nothing else to do.
            break
        }
    }
}
