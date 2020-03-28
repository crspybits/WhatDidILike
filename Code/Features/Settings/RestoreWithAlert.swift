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

        guard let placesToImport = try? PlaceExporter.exportedPlaces(in: securityScopedFolder, accessor: .securityScoped) else {
            completion?()
            return
        }
        
        guard placesToImport.count > 0 else {
            let alert = UIAlertController(title: "No places need importing.", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentVC?.present(alert, animated: true, completion: nil)
            completion?()
            return
        }
        
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
