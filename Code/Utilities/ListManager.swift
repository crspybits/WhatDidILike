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

protocol ListManagerDelegate {
    func listManagerNumberOfRows(_ listManager: ListManager) -> UInt
    func listManager(_ listManager: ListManager, itemForRow row: UInt) -> String
}

class ListManager : SMModal {
    fileprivate var delegate:ListManagerDelegate!
    @IBOutlet weak var newListItem: UITextField!
    @IBOutlet weak var tableView: UITableView!
    let cellReuseId = "CellReuseId"
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        let navButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        navigationItem.rightBarButtonItem = navButton
        newListItem.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
    }
    
    @objc private func doneAction() {
        close()
    }
    
    static func showFrom(parentVC: UIViewController, delegate: ListManagerDelegate) {
        let listManager = ListManager(nibName: "ListManager", bundle: nil)
        listManager.modalSize = CGSize(width: parentVC.view.frameWidth*0.9, height: parentVC.view.frameHeight*0.9)
        listManager.modalParentVC = parentVC
        listManager.show()
    }
    
    @IBAction func newListItemAction(_ sender: Any) {
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
        return cell
    }
}
