//
//  RestoreWithAlert.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/22/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import SMCoreLib

class RestoreWithAlert {
    private weak var parentVC: UIViewController?
    private var activity:UIAlertController!
    private var placesToImport: [PlaceExporter.ExportedPlace]!
    private var current = 1
    private var securityScopedFolder: URL!
    private var completion:(()->())?
    
    init(parentVC: UIViewController) {
        self.parentVC = parentVC
    }
    
    func start(usingSecurityScopedFolder securityScopedFolder: URL, completion:(()->())? = nil) {
        self.securityScopedFolder = securityScopedFolder

        guard let allPlacesToImport = try? PlaceExporter.exportedPlaces(in: securityScopedFolder, accessor: .securityScoped) else {
            completion?()
            return
        }
    
        var placesToImport: [PlaceExporter.ExportedPlace]!
        
        // Reduce the places to import by those that are already in core data.
        do {
            placesToImport = try allPlacesToImport.filter { exportedPlace in
                let existingCoreDataPlace = try Place.fetchObject(withUUID: exportedPlace.uuid)
                return existingCoreDataPlace == nil
            }
        } catch let error {
            let alert = UIAlertController(title: "Error determining places needing import: \(error)", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentVC?.present(alert, animated: true, completion: nil)
            completion?()
            return
        }
        
        let numberOfPlacesAlreadyExported = allPlacesToImport.count - placesToImport.count

        guard placesToImport.count > 0 else {
            let title:String
            if numberOfPlacesAlreadyExported > 0 {
                title = "No places need importing-- they have already been imported."
            }
            else {
                title = "No places need importing."
            }
            
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentVC?.present(alert, animated: true, completion: nil)
            completion?()
            return
        }
        
        if numberOfPlacesAlreadyExported > 0 {
            let alert = UIAlertController(title: "\(numberOfPlacesAlreadyExported) place(s) have already been imported-- importing others.", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Continue", style: .default) {[unowned self] _ in
                self.finishStart(placesToImport: placesToImport, completion: completion)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) {_ in
                completion?()
            })
            self.parentVC?.present(alert, animated: true)
        }
        else {
            finishStart(placesToImport: placesToImport, completion: completion)
        }
    }
    
    private func finishStart(placesToImport: [PlaceExporter.ExportedPlace], completion:(()->())? = nil) {
        do {
            try Place.createLargeImagesDirectoryIfNeeded()
        } catch let error {
            let alert = UIAlertController(title: "Alert!", message: "Could not create large images folder: \(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentVC?.present(alert, animated: true, completion: nil)
            completion?()
            return
        }

        activity = UIAlertController(title: "Importing...", message: nil, preferredStyle: .alert)
        activity.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.placesToImport = nil
        }))
        parentVC?.present(activity, animated: true, completion: nil)
        
        self.completion = completion
        self.placesToImport = placesToImport
        importNext()
    }
    
    private func importNext() {
        guard let placesToImport = placesToImport,
            placesToImport.count > 0 else {
            activity.dismiss(animated: true, completion: nil)
            completion?()
            return
        }
        
        self.activity.message = "Importing place \(current)"
        current += 1
        
        let nextPlace = self.placesToImport.remove(at: placesToImport.endIndex-1)
        
        do {
            try Place.import(from: nextPlace.location, in: securityScopedFolder, accessor: .securityScoped)
        } catch let error {
            activity.dismiss(animated: true) {[unowned self] in
                let alert = UIAlertController(title: "Alert!", message: "Error importing: \(error)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.parentVC?.present(alert, animated: true, completion: nil)
                self.completion?()
            }
            return
        }
        
        // Async so that other work on the main thread can take place.
        DispatchQueue.main.async {
            self.importNext()
        }
    }
}
