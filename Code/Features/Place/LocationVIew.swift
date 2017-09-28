//
//  LocationView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import MapKit
import SMCoreLib

class LocationView: UIView, XibBasics {
    typealias ViewType = LocationView
    @IBOutlet weak var address: TextView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var gpsLocation: UISegmentedControl!
    @IBOutlet weak var specificDescription: TextView!
    @IBOutlet weak var ratingContainer: UIView!
    let rating = RatingView.create()!
    
    // Used when converting an address to coordinates.
    private var addressCoords: CLLocation?
    
    private static let numberOfTimesLocationServicesFailed = SMPersistItemInt(name: "LocationView.numberOfTimesLocationServicesFailed", initialIntValue: 0, persistType: .userDefaults)
    
    // I'm no longer using this to establish the actual location
    // of the user/place, but rather to supply an initial set location
    // for purposes of the user interface and displaying the pulsing blue
    // dot with the users location. I cannot find a way to zoom in
    // on the pulsing blue dot without also specifying the lat/long of
    // the user. I can't be assured of a reasonable level of accuracy
    // with the lat/long coords if I directly obtain the coords from
    // the map just after I turn on the display of the pulsing blue dot.
    var ll:LatLong!
    
    // coordinates that were stored by the user previously to coming
    // into AddChangeRestaurant this time.
    var oldCoords:CLLocation?
    
    var convertAddress: GeocodeAddressToLatLong?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: address)
        Layout.format(textBox: specificDescription)
        
        rating.frameWidth = ratingContainer.frameWidth
        ratingContainer.addSubview(rating)
    }
    
    func setup(withLocation location: Location, viewController: UIViewController) {
        address.text = location.address
        specificDescription.text = location.specificDescription
        convertAddress = GeocodeAddressToLatLong(delegate: self, andViewController: viewController)
    }
    
    enum GPSLocationType : Int {
        case previous = 0
        case current = 1
        case address = 2
    }

    @IBAction func gpsLocationAction(_ sender: Any) {
        addressCoords = nil
        
        let gpsLocationType = GPSLocationType(rawValue: gpsLocation.selectedSegmentIndex)!
        switch gpsLocationType {
        case .current:
            LocationView.numberOfTimesLocationServicesFailed.intValue = 0
            ll = LatLong(delegate: self)
            
        case .previous:
            // Need to set ll to nil so that there is no record of a change
            // to the lat/long for dataHasChanged.

            if ll != nil {
                ll.stopWithoutCallback()
            }
            ll = nil
            if oldCoords == nil {
                map.showsUserLocation = false
                removeAnnotation()
            } else {
                annnotateMap(coords: oldCoords!.coordinate)
            }
            
        case .address:
            map.showsUserLocation = false
            removeAnnotation()

            // If there is an address, attempt to
            // geocode that address.
            geocodeIfNeeded()
 
            // If they are asking to use an address, then stop dealing with current GPS location. This is mostly to deal with the user having location services turned off. If location services are turned off, shouldn't give them an error and switch GPS location button to "Off" after they select "Address".
            if ll != nil {
                ll.stopWithoutCallback()
                ll = nil
            }
        }
    }
    
    private func removeAnnotation() {
        // Remove annotation if there is one on the map
        // Don't want the pin plus the pulsing blue dot
        if map.annotations.count > 0 {
            map.removeAnnotations(map.annotations)
        }
    }
    
    private func annnotateMap(coords: CLLocationCoordinate2D) {
        map.showsUserLocation = false
        removeAnnotation()
        let r = MKCoordinateRegionMakeWithDistance(coords, 1000, 1000)
        map.setRegion(r, animated: true)
        
        let annotation = MapAnnotation(coordinate: coords)

        /*
         I first tried to use MKPinAnnotationView's. But I can't figure out
         how to add these to the map. It seems you have to use the
         MKMapViewDelegate technique. And that seems more technology than
         is needed for what I was trying to do, which is just have a map
         with a pinlocating the existing GPS coordindates.
         
         MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
         [pin setPinColor:MKPinAnnotationColorRed];
         [pin setAnimatesDrop:YES];
         */
         map.addAnnotation(annotation!)
    }
    
    func geocodeIfNeeded() {
        let gpsLocationType = GPSLocationType(rawValue: gpsLocation.selectedSegmentIndex)!
        if gpsLocationType == .address {
            let spaces = CharacterSet.whitespacesAndNewlines
            address.text = address.text.trimmingCharacters(in: spaces)
            if address.text.count > 0 {
                // GPS location button is off and we have an address
                // Attempt to geocode it.
     
                // Previously, I locked the UI at this point...
                convertAddress?.lookupAddress(address.text , withExitMethod: {
                })
            }
        }
    }
}

extension LocationView : LatLongDelegate {
    func haveReasonablyAccurateCoordinates() {
    }
    
    func finishedAttemptingToObtainCoordinates() {
    }
}

extension LocationView : GeocodeAddressToLatLongDelegate {
    // This will be called if a failure occurs converting an address to
    // coordinates. An alert view will be given to the user before this is
    // called.
    func failureLookingupAddress() {
    }

    // Called when successful; with the latitude and longitude of the successful
    // conversion.
    func successLookingupAddress(_ latitude: Float, andLongitude longitude: Float) {
    }
}
