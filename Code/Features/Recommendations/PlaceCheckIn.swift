//
//  CheckIn.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/12/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import SMCoreLib

class PlaceCheckIn: NSObject {
    enum CheckInError: Error {
        case noLocations
        case noUserAuthorization
        case noCoords
    }
    
    let thresholdDistance: CLLocationDistance = 500 // meters
    
    private var ll:LatLong!
    private var completion: ((Result<Location?, Error>)->())?
    private let place: Place
    private var placeLocations: Set<Location>!
    private weak var parent: UIViewController!
    
    init(_ place: Place, parent: UIViewController) {
        self.place = place
        self.parent = parent
    }
    
    func start() {
        nearby {[unowned self] result in
            switch result {
            case .success(let location):
                if let location = location {
                    let alert = UIAlertController(title: "Check-in?", message: "This doesn't do any network actions. The check-in is purely on your device.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        let checkIn = Checkin.newObject()
                        location.addToCheckin(checkIn)
                        location.save()
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                    }))
                    self.parent.present(alert, animated: true, completion: nil)
                }
                
            case .failure:
                break
            }
        }
    }
    
    // Is the device near one of the locations in the Place?
    private func nearby(completion: @escaping (Result<Location?, Error>)->()) {
        guard let placeLocations = place.locations as? Set<Location> else {
            completion(.failure(CheckInError.noLocations))
            return
        }
        
        self.placeLocations = placeLocations
        
        // Don't check-in if place created recently.
        guard let creationDate = place.creationDate, place.dissimilarDates(date1:creationDate as Date, date2: Date()) else {
            completion(.success(nil))
            return
        }
        
        // Only determine our location if there are actual CLLocation's to compare against.
        let clLocations = placeLocations.map{$0.location}.compactMap {$0}
        guard clLocations.count > 0 else {
            completion(.success(nil))
            return
        }
        
        let checkIns = self.placeLocations
            .map {$0.checkin as? Set<Checkin>}
            .compactMap {$0}
            .flatMap { $0 }
        
        let current = Date()

        // Don't check-in if we've checked in recently.
        let recentCheckIns = checkIns
            .filter { !$0.dissimilarDates(date1: $0.date!, date2: current)}
        
        guard recentCheckIns.count == 0 else {
            completion(.success(nil))
            return
        }
        
        self.completion = completion
        ll = LatLong(delegate: self)
    }
    
    deinit {
        ll?.stop()
    }
}

extension PlaceCheckIn: LatLongDelegate {
    func userDidNotAuthorizeLocationServices() {
        Log.msg("userDidNotAuthorizeLocationServices")
        completion?(.failure(CheckInError.noUserAuthorization))
    }
    
    func haveReasonablyAccurateCoordinates() {
        if ll.coords == nil {
            Log.msg("haveReasonablyAccurateCoordinates: No coords")
            ll.stop()
            completion?(.failure(CheckInError.noCoords))
        }
        else {
            let coords = ll.coords!
            Log.msg("haveReasonablyAccurateCoordinates: \(coords)")
            ll.stop()
            
            for location in placeLocations {
                if let clLocation = location.location,
                    clLocation.distance(from: coords) < thresholdDistance {
                    completion?(.success(location))
                    return
                }
            }
            
            completion?(.success(nil))
        }
    }
    
    func finishedAttemptingToObtainCoordinates() {
        Log.msg("finishedAttemptingToObtainCoordinates")
    }
}
