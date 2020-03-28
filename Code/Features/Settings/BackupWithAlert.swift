//
//  BackupWithAlert.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/21/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

class BackupWithAlert {
    private weak var parentVC: UIViewController?
    private var activity:UIAlertController!
    private var placesToExport: [Place]!
    private var current = 1
    private var securityScopedFolder: URL!
    private var completion:(()->())?
    private var placeExporter:PlaceExporter!
    
    init(parentVC: UIViewController) {
        self.parentVC = parentVC
    }
    
    func start(usingSecurityScopedFolder securityScopedFolder: URL, completion:(()->())? = nil) {
        self.securityScopedFolder = securityScopedFolder
        guard let (placesToExport, _) = Place.needExport() else {
            completion?()
            return
        }
        
        guard placesToExport.count > 0 else {
            let alert = UIAlertController(title: "No places need exporting", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentVC?.present(alert, animated: true, completion: nil)
            completion?()
            return
        }
        
        do {
            placeExporter = try PlaceExporter(parentDirectory: securityScopedFolder, accessor: .securityScoped)
        } catch let error {
            let alert = UIAlertController(title: "Alert!", message: "There was an error initializing the export: \(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            parentVC?.present(alert, animated: true, completion: nil)
            completion?()
            return
        }
        
        activity = UIAlertController(title: "Exporting...", message: nil, preferredStyle: .alert)
        activity.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.placesToExport = nil
        }))
        parentVC?.present(activity, animated: true, completion: nil)
        
        self.completion = completion
        self.placesToExport = placesToExport
        exportNext()
    }
    
    private func exportNext() {
        guard let placesToExport = placesToExport, placesToExport.count > 0 else {
            activity.dismiss(animated: true, completion: nil)
            completion?()
            return
        }
        
        self.activity.message = "Exporting place \(current)"
        current += 1
        
        let nextPlace = self.placesToExport.remove(at: placesToExport.endIndex-1)
        
        do {
            try placeExporter.export(place: nextPlace, accessor: .securityScoped)
            nextPlace.save()
        } catch let error {
            activity.dismiss(animated: true) {[unowned self] in
                let alert = UIAlertController(title: "Alert!", message: "Error exporting: \(error)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.parentVC?.present(alert, animated: true, completion: nil)
                self.completion?()
            }
            return
        }
        
        // Async so that other work on the main thread can take place.
        DispatchQueue.main.async {
            self.exportNext()
        }
    }
}
