//
//  SettingsVC.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/20/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

private struct CellDescription {
    let cellName: String
    let handler:(_ id: String, IndexPath, SettingsVC)->(UITableViewCell?)
    
    func register(tableView: UITableView) {
        tableView.register(UINib(nibName: cellName, bundle: nil), forCellReuseIdentifier: cellName)
    }
}

class SettingsVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    weak var syncCellDelegate: SyncSettingsCellDelegate!

    private let syncCell = CellDescription(cellName: "SyncSettingsCell") { id, indexPath, settingsVC in

        guard let cell = settingsVC.tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as? SyncSettingsCell else {
            return nil
        }
        
        cell.parentVC = settingsVC
        cell.updatePlacesNeedingBackup()
        cell.delegate = settingsVC
        return cell
    }
    
    private let placeDeletionCell = CellDescription(cellName: "PlaceDeletionOptionsCell") { id, indexPath, settingsVC in

        guard let cell = settingsVC.tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as? PlaceDeletionOptionsCell else {
            return nil
        }
        
        settingsVC.syncCellDelegate = cell
        
        return cell
    }
    
    // Map from row number to description.
    private var cellDescriptions: [Int: CellDescription] {
        return [
            0: syncCell,
            1: placeDeletionCell
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        
        for (_, cellDescription) in cellDescriptions {
            cellDescription.register(tableView: tableView)
        }
        
        navigationItem.title = "Settings"
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // To update numbers of places in SyncSettingsCell if they have changed.
        tableView.reloadData()
    }
}

extension SettingsVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellDescriptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        guard let cellDescription = cellDescriptions[indexPath.row],
            let cell = cellDescription.handler(cellDescription.cellName, indexPath, self) else {
            return UITableViewCell()
        }

        return cell
    }
}

extension SettingsVC: SyncSettingsCellDelegate {
    func backupFolder(isAvailable: Bool) {
        syncCellDelegate?.backupFolder(isAvailable: isAvailable)
    }
}
