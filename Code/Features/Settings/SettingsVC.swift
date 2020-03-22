//
//  SettingsVC.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/20/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController {
    let syncCellName = "SyncSettingsCell"
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.register(UINib(nibName: syncCellName, bundle: nil), forCellReuseIdentifier: syncCellName)
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        guard let cell = tableView.dequeueReusableCell(withIdentifier: syncCellName, for: indexPath) as? SyncSettingsCell else {
            return UITableViewCell()
        }
        
        cell.parentVC = self
        cell.updatePlacesNeedingBackup()

        return cell
    }
}

