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
    private var actualNumberOfImports = 0
    private var cancel = false
    
    init(parentVC: UIViewController) {
        self.parentVC = parentVC
    }
    
    func start(usingSecurityScopedFolder securityScopedFolder: URL, completion:(()->())? = nil) {
        self.securityScopedFolder = securityScopedFolder
        cancel = false
        
        guard let placesToImport = try? PlaceExporter.exportedPlaces(in: securityScopedFolder, accessor: .securityScoped) else {
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
            self.cancel = true
        }))
        parentVC?.present(activity, animated: true, completion: nil)
        
        self.completion = completion
        self.placesToImport = placesToImport
        importNext()
    }
    
    private func importNext() {
        guard !cancel else {
            return
        }
        
        guard let placesToImport = placesToImport,
            placesToImport.count > 0 else {
            
            let title:String
            if actualNumberOfImports == 0 {
                title = "No places need importing-- they have already been imported."
            }
            else {
                let terms: String
                if actualNumberOfImports == 1 {
                    terms = "place was"
                }
                else {
                    terms = "places were"
                }
                
                title = "\(actualNumberOfImports) \(terms) imported."
            }
            
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            activity.dismiss(animated: true) {[unowned self] in
                self.parentVC?.present(alert, animated: true) {[unowned self] in
                    self.completion?()
                }
            }

            return
        }
        
        self.activity.message = "Importing place \(current)"
        current += 1
        
        let nextPlace = self.placesToImport.remove(at: placesToImport.endIndex-1)
        
        do {
            if let _ = try Place.import(from: nextPlace.location, in: securityScopedFolder, accessor: .securityScoped) {
                actualNumberOfImports += 1
            }
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
