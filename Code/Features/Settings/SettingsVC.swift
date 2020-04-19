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
    var compareCell: CompareBackupCell?
    var deletionOptionsCell: PlaceDeletionOptionsCell?
    private var spinner:Spinner?

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
        
        settingsVC.deletionOptionsCell = cell
                
        return cell
    }
    
    private let compareBackupCell = CellDescription(cellName: "CompareBackupCell") { id, indexPath, settingsVC in

        guard let cell = settingsVC.tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as? CompareBackupCell else {
            return nil
        }

        cell.parentVC = settingsVC
        settingsVC.compareCell = cell

        return cell
    }
    
    // Map from row number to description.
    private var cellDescriptions: [Int: CellDescription] {
        var result = [
            0: syncCell,
            1: placeDeletionCell,
        ]
        
        #if DEBUG
            result[2] = compareBackupCell
        #endif
        
        return result
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if spinner == nil {
            spinner = Spinner(superview: view)
        }
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

extension SettingsVC: SettingsCellDelegate {
    func backupFolder(isAvailable: Bool) {
        deletionOptionsCell?.backupFolder(isAvailable: isAvailable)
        compareCell?.backupFolder(isAvailable: isAvailable)
    }
    
    func startSpinner()  {
        spinner?.start()
    }
    
    func stopSpinner() {
        spinner?.stop()
    }
}
