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
    var addressWasUpdated:(()->())?
    @IBOutlet private weak var map: MKMapView!
    @IBOutlet private weak var gpsLocation: UISegmentedControl!
    @IBOutlet weak var specificDescription: TextView!
    @IBOutlet private weak var ratingContainer: UIView!
    private let rating = RatingView.create()!
    @IBOutlet weak var imagesContainer: UIView!
    weak var delegate:GPSDelegate!
    
    private var defaultRegion:MKCoordinateRegion!
    
    fileprivate weak var viewController: UIViewController!
    fileprivate var location: Location!
    fileprivate var place: Place!
    private let images = ImagesView.create()!

    // I'm no longer using this to establish the actual location
    // of the user/place, but rather to supply an initial set location
    // for purposes of the user interface and displaying the pulsing blue
    // dot with the users location. I cannot find a way to zoom in
    // on the pulsing blue dot without also specifying the lat/long of
    // the user. I can't be assured of a reasonable level of accuracy
    // with the lat/long coords if I directly obtain the coords from
    // the map just after I turn on the display of the pulsing blue dot.
    private var ll:LatLong!
    
    private var currentCoords:CLLocation? {
        return location.location
    }
    
    private var convertAddress: GeocodeAddressToLatLong?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: address)
        Layout.format(textBox: specificDescription)
        address.autocapitalizationType = .words
        address.autocorrectionType = .no
        specificDescription.autocapitalizationType = .sentences
        
        rating.frameWidth = ratingContainer.frameWidth
        ratingContainer.addSubview(rating)
        
        images.frameWidth = imagesContainer.frameWidth
        images.frameHeight = imagesContainer.frameHeight
        imagesContainer.addSubview(images)
        
        images.lowerLeftLabel.text = "Location pictures"
    }
    
    func setup(withLocation location: Location, place: Place, viewController: UIViewController) {
        self.location = location
        self.place = place
        self.viewController = viewController
        address.text = location.address
        specificDescription.text = location.specificDescription
        convertAddress = GeocodeAddressToLatLong(delegate: self, andViewController: viewController)
        defaultRegion = map.region
        
        if let currentCoords = currentCoords {
            // We have coords; show them as a point on the map
            annotateMap(coords: currentCoords.coordinate)
        }
        
        // So we can tap on the map to navigate to the location
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGestureAction))
        map.addGestureRecognizer(tap)
        
        rating.setup(withRating: location.rating!)
        
        images.setup(withParentVC:viewController, andImagesObj: location)
        
        address.save = {[unowned self] update in
            location.address = update
            location.save()
            self.addressWasUpdated?()
        }
        
        specificDescription.save = { update in
            location.specificDescription = update
            location.save()
        }
        
        Layout.format(location: self)
    }
    
    // Useful if the location is new, and you need to establish Current coordinates.
    func establishCurrentCoordinates() {
        gpsLocation.selectedSegmentIndex = GPSLocationType.current.rawValue
        gpsLocationAction()
    }
    
    func close() {
        ll?.stopWithoutCallback()
        ll?.cleanup()
        delegate?.stoppedUsingGPS(self)
        convertAddress?.cleanup()
    }
    
    @objc private func tapGestureAction() {
        mapTap()
    }
    
    enum GPSLocationType : Int {
        case previous = 0
        case current = 1
        case address = 2
    }

    @IBAction func gpsLocationAction(_ sender: Any) {
        gpsLocationAction()
    }
    
    private func gpsLocationAction() {
        let gpsLocationType = GPSLocationType(rawValue: gpsLocation.selectedSegmentIndex)!
        switch gpsLocationType {
        case .current:
            Parameters.numberOfTimesLocationServicesFailed.intValue = 0
            delegate?.startedUsingGPS(self)
            ll = LatLong(delegate: self)
            
        case .previous:
            // Need to set ll to nil so that there is no record of a change
            // to the lat/long.

            if ll != nil {
                ll.stopWithoutCallback()
            }
            ll = nil
            
            showPreviousLocation()
            
        case .address:
            map.showsUserLocation = false
            removeAnnotation()

            // If they are asking to use an address, then stop dealing with current GPS location. This is mostly to deal with the user having location services turned off. If location services are turned off, shouldn't give them an error and switch GPS location button to "Off" after they select "Address".
            if ll != nil {
                ll.stopWithoutCallback()
                ll = nil
            }
            
            // If there is an address, attempt to geocode that address.
            geocodeIfNeeded()
        }
    }
    
    private func removeAnnotation() {
        // Remove annotation if there is one on the map
        // Don't want the pin plus the pulsing blue dot
        if map.annotations.count > 0 {
            map.removeAnnotations(map.annotations)
        }
    }
    
    private func annotateMap(coords: CLLocationCoordinate2D) {
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
    
    private func geocodeIfNeeded() {
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
    
    func showUserLocation() {
        map.showsUserLocation = true
        let r = MKCoordinateRegionMakeWithDistance(ll.coords.coordinate, 1000, 1000)
        map.setRegion(r, animated: true)
        removeAnnotation()
    }
    
    private func mapTap() {
        // TODO: Should we do an `updateCoordinates` here?
        if let currentCoords = currentCoords {
            if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
                var message = "Navigate "
                if let placeName = place.name {
                    message += "to \(placeName) "
                }
                message += "using: "
                
                let alert = UIAlertController(title: message, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { alert in
                })
                alert.addAction(UIAlertAction(title: "Apple Maps", style: .default) { alert in
                    self.navigateUsingAppleMaps(to: currentCoords)
                })
                alert.addAction(UIAlertAction(title: "Google Maps", style: .default) { alert in
                    self.navigateUsingGoogleMaps(to: currentCoords)
                })
                viewController.present(alert, animated: true, completion: nil)
            }
            else {
                // No Google maps; just use the native map app
                navigateUsingAppleMaps(to: currentCoords)
            }
        }
    }
    
    private func navigateUsingGoogleMaps(to coords:CLLocation) {
        // URL from https://developers.google.com/maps/documentation/urls/guide#directions-action
        let googleMapsURL = URL(string:"https://www.google.com/maps/dir/?api=1&destination=\(coords.coordinate.latitude),\(coords.coordinate.longitude)")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(googleMapsURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(googleMapsURL)
        }
    }
    
    // Based on https://stackoverflow.com/questions/12504294/programmatically-open-maps-app-in-ios-6/46507696#46507696
    private func navigateUsingAppleMaps(to coords:CLLocation, locationName: String? = nil) {
        var mapItemName:String?
        if let locationName = locationName {
            mapItemName = locationName
        }
        else {
            mapItemName = place.name
        }
    
        let placemark = MKPlacemark(coordinate: coords.coordinate, addressDictionary:nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = mapItemName
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        let currentLocationMapItem = MKMapItem.forCurrentLocation()

        MKMapItem.openMaps(with: [currentLocationMapItem, mapItem], launchOptions: launchOptions)
    }
    
    fileprivate func saveNewCoordinatesIfNeeded(newLocation: CLLocation) {
        // Check to see if the new coordinates are (a) really far away
        // from the old coordinates, and if so alert the user to this
        // fact, and (b) better quality; If they are better quality and
        // relatively close to old coordinates just update coords
        // silently; if worse, throw away new silently.
    
        let THRESHOLD_DISTANCE_METERS = 100.0
        var doneAlert = false
        
        func save() {
            location.location = newLocation
            
            // If we're currently sorting by distance, update the distance from that location datum.
            switch Parameters.orderFilter {
            case .distance:
                if let clLocation = Parameters.sortLocation {
                    location.setSortingDistance(from: clLocation)
                }
                
            case .name:
                break
                
            case .rating:
                break
            }
            
            location.save()
        }
    
        if let currentCoords = currentCoords {
            let dist = newLocation.distance(from: currentCoords)
            if dist > THRESHOLD_DISTANCE_METERS {
                let miles = Location.metersToMiles(meters: Float(dist))
                let message = "The new coordinates are \(miles) miles away from the previous coordinates."
                let alert = UIAlertController(title: message, message: nil, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { alert in
                    self.gpsLocation.selectedSegmentIndex = GPSLocationType.previous.rawValue
                    self.showPreviousLocation()
                })
                alert.addAction(UIAlertAction(title: "Use New", style: .destructive) { alert in
                    save()
                })
                viewController?.present(alert, animated: true, completion: nil)
            } else {
                // Greater accuracy numbers actually mean poorer results
                if (newLocation.horizontalAccuracy > currentCoords.horizontalAccuracy) {
                    // Poorer new results, so get rid of them
                    Log.msg("Less accurate new \(newLocation.horizontalAccuracy) coords; keeping previous \(currentCoords.horizontalAccuracy)")
                }
                else {
                    save()
                }
            }
        }
        else {
            save()
        }
    }
    
    private func showPreviousLocation() {
        map.showsUserLocation = false
        if let currentCoords = currentCoords {
            annotateMap(coords: currentCoords.coordinate)
        }
        else {
            removeAnnotation()
            map.setRegion(defaultRegion, animated: false)
        }
    }
    
    deinit {
        Log.msg("deinit")
    }
}

extension LocationView : LatLongDelegate {
    func userDidNotAuthorizeLocationServices() {
        delegate?.stoppedUsingGPS(self)
    }
    
    func haveReasonablyAccurateCoordinates() {
        Log.msg("haveReasonablyAccurateCoordinates")

        // Wait until now to show the user location, because my implementation of `showUserLocation` depends on ll having established the user location.
        showUserLocation()
    }
    
    func finishedAttemptingToObtainCoordinates() {
        delegate?.stoppedUsingGPS(self)
        Log.msg("finishedAttemptingToObtainCoordinates: ll: \(ll)")
        if ll.coords == nil {
            // We could not obtain coords; change the gpsLocation to `previous`
            // to indicate to the user that we failed getting coords.
            gpsLocation.selectedSegmentIndex = GPSLocationType.previous.rawValue
            showPreviousLocation()

            // If we do this too many times, then turn off showing this message until the user presses the "Current" GPS location button.
            if Parameters.numberOfTimesLocationServicesFailed.intValue < Parameters.limitLocationServicesFailed {
                Alert.show(fromVC: viewController, withTitle: "Could not obtain your current location.", message: "Are location services turned off?")
                Parameters.numberOfTimesLocationServicesFailed.intValue += 1
            }
        }
        else {
            let mapLocation = map.userLocation.location
            
            // I'm going to ignore whether or not the map is still updating
            // the location (mapLocation.updating) and just take the most
            // accurate coordinates from ll or the map.
            
            var mostAccurateLocation: CLLocation
            if mapLocation != nil && mapLocation!.horizontalAccuracy < ll.coords.horizontalAccuracy {
                mostAccurateLocation = mapLocation!
                Log.msg("Taking coords from map (accuracy = \(mapLocation!.horizontalAccuracy)")
            }
            else {
                mostAccurateLocation = ll.coords
                Log.msg("Taking coords from ll")
            }

            saveNewCoordinatesIfNeeded(newLocation: mostAccurateLocation)
        }
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
        let gpsLocationType = GPSLocationType(rawValue: gpsLocation.selectedSegmentIndex)!
        if gpsLocationType == .address {
            let addressLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            annotateMap(coords: addressLocation.coordinate)
            saveNewCoordinatesIfNeeded(newLocation: addressLocation)
        }
    }
}
