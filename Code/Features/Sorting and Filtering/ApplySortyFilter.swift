//
//  ApplySortyFilter.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/18/18.
//  Copyright © 2018 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import SMCoreLib

protocol ApplySortyFilterDelegate : class {
    func sortyFilter(reset: ApplySortyFilter)
    func sortyFilter(sortFilterByParameters: ApplySortyFilter)
    
    func sortyFilter(startUsingLocationServices:ApplySortyFilter)
    func sortyFilter(stopUsingLocationServices:ApplySortyFilter)
}

class ApplySortyFilter: NSObject {
    private var ll:LatLong!
    private var convertAddress: GeocodeAddressToLatLong?
    weak var delegate:ApplySortyFilterDelegate?
    
    init(withViewController viewController: UIViewController) {
        super.init()
        convertAddress = GeocodeAddressToLatLong(delegate: self, andViewController: viewController)
    }
    
    deinit {
        convertAddress?.cleanup()
    }
    
    func apply() {
        delegate?.sortyFilter(reset: self)
        
        switch Parameters.sortingOrder {
        case .distance:
            if Parameters.tryAgainFilter != .dontUse {
                computeTryAgain()
            }

            asyncComputeDistances()
            
        case .name:
            computeAllFilters()
            
        case .rating:
            computeRatings()
            computeAllFilters()
        }
    }
    
    private func computeAllFilters() {
        if Parameters.tryAgainFilter != .dontUse {
            computeTryAgain()
        }
    
        if Parameters.distanceFilter == .use {
            asyncComputeDistances()
        }
        else {
            delegate?.sortyFilter(sortFilterByParameters: self)
        }
    }
    
    private func asyncComputeDistances() {
        switch Parameters.location {
        case .me:
            delegate?.sortyFilter(startUsingLocationServices: self)

            // Recompute distances of all locations from our location. First, we need our location.
            Parameters.numberOfTimesLocationServicesFailed.intValue = 0
            ll = LatLong(delegate: self)
            
        case .address:
            if Parameters.orderAddress.count > 0 {
                delegate?.sortyFilter(startUsingLocationServices: self)

                // Attempt to geocode the address
                convertAddress?.lookupAddress(Parameters.orderAddress, withExitMethod: {
                })
            }
        }
    }
    
    private func computeTryAgain() {
        guard let locations = Location.fetchAllObjects() else {
            return
        }
        
        for location in locations {
            computeTryAgain(forLocation: location)
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    // Also sets `internalGoBack`.
    private func computeTryAgain(forLocation location: Location) {
        if let again = location.rating?.again {
            location.internalGoBack = again.boolValue as NSNumber
            return
        }
        else {
            if let items = location.place?.items, items.count > 0 {
                for itemObj in items {
                    let item = itemObj as! Item
                    
                    if let comments = item.comments, comments.count > 0 {
                        for commentObj in comments {
                            let comment = commentObj as! Comment
                            if let again = comment.rating?.again {
                                location.internalGoBack = again.boolValue as NSNumber
                                return
                            }
                        }
                    }
                }
            }
        }
        
        location.internalGoBack = nil
    }
    
    // Also sets that rating.
    private func computeRating(forLocation location: Location) {
        var resultRating:Float = 0.0
        var numberCommentRatings:Int = 0
        
        if let rating = rating(location.rating) {
            // If the location itself has a rating, use that exclusively.
            location.sortingRating = rating
        }
        else {
            if let items = location.place?.items, items.count > 0 {
                for itemObj in items {
                    let item = itemObj as! Item
                    
                    if let comments = item.comments, comments.count > 0 {
                        for commentObj in comments {
                            let comment = commentObj as! Comment
                            if let rating = rating(comment.rating) {
                                numberCommentRatings += 1
                                resultRating += rating
                            }
                        }
                    }
                }
            }
            
            if numberCommentRatings > 0 {
                // Have some comment ratings. Average them.
                location.sortingRating = resultRating/Float(numberCommentRatings)
            }
            else {
                // A zero initial value will make the locations with no ratings at all sink to the bottom. This will be ambiguous with locations that actually have a 0 rating, but what's a guy to do?
                location.sortingRating = 0.0
            }
        }
    }
    
    // Take into account me/them in terms of ratings. E.g., if I give a rating that should have more weight than if someone else gives a rating.
    private func rating(_ rating: Rating?) -> Float? {
        if let rating = rating {
            let ratingValue = rating.rating
            if let meThem = rating.meThem {
                if meThem.boolValue {
                    /*
                    Increase by the factor, but limit result to 1.
                    Approximating: f(r, m) <= 1; f(r, m) > r unless r = 1
                    */
                    if ratingValue == 1.0 {
                        return ratingValue
                    }
                    else {
                        return Float(1.0 - pow(1.1, -30.0 * Double(ratingValue)))
                    }
                }
                else {
                    // Decrease by a factor
                    return ratingValue * 0.7
                }
            }
            else {
                return ratingValue
            }
        }
        else {
            return nil
        }
    }
    
    private func computeRatings() {
        guard let locations = Location.fetchAllObjects() else {
            return
        }
        
        for location in locations {
            computeRating(forLocation: location)
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    private func computeDistances(from: CLLocation) {
        guard let locations = Location.fetchAllObjects() else {
            return
        }
        
        for location in locations {
            location.setSortingDistance(from: from)
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
        
        delegate?.sortyFilter(sortFilterByParameters: self)
    }
}

extension ApplySortyFilter : LatLongDelegate {
    func userDidNotAuthorizeLocationServices() {
        delegate?.sortyFilter(stopUsingLocationServices: self)
    }
    
    func haveReasonablyAccurateCoordinates() {
        delegate?.sortyFilter(stopUsingLocationServices: self)
        
        Log.msg("haveReasonablyAccurateCoordinates: ll: \(ll)")
        if ll.coords == nil {
            ll.stop()
            Alert.show(withTitle: "Could not obtain your current location.", message: "Are location services turned off?")
        }
        else {
            let coords = ll.coords!
            ll.stop()
            Log.msg("Coords from ll: \(coords)")
            Parameters.sortLocation = coords
            computeDistances(from: coords)
        }
    }
    
    func finishedAttemptingToObtainCoordinates() {
        delegate?.sortyFilter(stopUsingLocationServices: self)
    }
}

extension ApplySortyFilter : GeocodeAddressToLatLongDelegate {
    // This will be called if a failure occurs converting an address to
    // coordinates. An alert view will be given to the user before this is
    // called.
    func failureLookingupAddress() {
        Log.error("failureLookingupAddress")
        delegate?.sortyFilter(stopUsingLocationServices: self)
    }

    // Called when successful; with the latitude and longitude of the successful conversion.
    func successLookingupAddress(_ latitude: Float, andLongitude longitude: Float) {
        delegate?.sortyFilter(stopUsingLocationServices: self)
        let addressLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        Log.msg("Coords from ll: \(addressLocation)")
        Parameters.sortLocation = addressLocation
        computeDistances(from: addressLocation)
    }
}
