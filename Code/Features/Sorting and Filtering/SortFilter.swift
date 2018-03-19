//
//  SortFilterModal.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/15/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib
import DGRunkeeperSwitch
import FLAnimatedImage
import BEMCheckBox

#if false

protocol SortFilterDelegate : class {
func sortFilter(_ sortFilterByParameters: SortFilter)
}

class SortFilter: SMModal {
    @IBOutlet weak var distanceFromContainer: UIView!
    @IBOutlet private weak var distanceSwitchContainer: UIView!
    private let distanceSwitch = DGRunkeeperSwitch()
    @IBOutlet private weak var upOrDownContainer: UIView!
    private let upOrDownSwitch = DGRunkeeperSwitch()
    private var spinner: Spinner!
    private var animatingEarthImageView:FLAnimatedImageView!
    @IBOutlet private weak var address: TextView!
    @IBOutlet weak var addressContainer: UIView!
    var delegate:SortFilterDelegate?
    @IBOutlet weak var alphabeticContainer: UIView!
    @IBOutlet weak var ratingContainer: UIView!
    @IBOutlet weak var distanceRadioButton: BEMCheckBox!
    @IBOutlet weak var ratingRadioButton: BEMCheckBox!
    @IBOutlet weak var alphabeticRadioButton: BEMCheckBox!
    private var radioButtonGroup:BEMCheckBoxGroup!
    private var ll:LatLong!
    private var convertAddress: GeocodeAddressToLatLong?
    @IBOutlet weak var tryAgainFilter: UISegmentedControl!
    let maxDistance:Float = 50
    @IBOutlet weak var distanceFilter: UISegmentedControl!
    @IBOutlet weak var distanceAmount: UILabel!
    @IBOutlet weak var distanceSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Sort/Filter"
        
        view.backgroundColor = UIColor.white
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        navigationItem.leftBarButtonItem = cancel
        
        let (imageView, gpsBarButton) = GPSExtras.spinner()
        animatingEarthImageView = imageView
        
        let apply = UIBarButtonItem(title: "Apply", style: .plain, target: self, action: #selector(applyAction))
        navigationItem.rightBarButtonItems = [apply, gpsBarButton]
        
        upOrDownSwitch.titles = ["Ascending", "Descending"]
        Layout.format(switch: upOrDownSwitch, usingSize: upOrDownContainer.frameSize)
        upOrDownSwitch.addTarget(self, action: #selector(upOrDownSwitchAction), for: .valueChanged)
        upOrDownContainer.addSubview(upOrDownSwitch)
        
        distanceSwitch.titles = ["Me", "Address"]
        Layout.format(switch: distanceSwitch, usingSize: distanceSwitchContainer.frameSize)
        distanceSwitch.addTarget(self, action: #selector(distanceSwitchAction), for: .valueChanged)
        distanceSwitchContainer.addSubview(distanceSwitch)
        
        let index = Parameters.orderFilter.isAscending ? 0 : 1
        upOrDownSwitch.setSelectedIndex(index, animated: false)
        
        Layout.format(textBox: address)
        
        formatBox(view: distanceFromContainer)
        formatBox(view: alphabeticContainer)
        formatBox(view: ratingContainer)
        
        distanceSwitchAction()
        
        radioButtonGroup = BEMCheckBoxGroup(checkBoxes: [distanceRadioButton, alphabeticRadioButton, ratingRadioButton])
        
        switch Parameters.orderFilter {
        case .distance:
            radioButtonGroup.selectedCheckBox = distanceRadioButton
            
        case .name:
            radioButtonGroup.selectedCheckBox = alphabeticRadioButton
            
        case .rating:
            radioButtonGroup.selectedCheckBox = ratingRadioButton
        }
        
        radioButtonGroup.mustHaveSelection = true
        
        address.autocapitalizationType = .sentences
        address.autocorrectionType = .no
        
        convertAddress = GeocodeAddressToLatLong(delegate: self, andViewController: self)
        
        address.save = { update in
            Parameters.orderAddress = update
        }
        address.text = Parameters.orderAddress
        
        tryAgainFilter.selectedSegmentIndex = Parameters.filterTryAgain.rawValue
        distanceFilter.selectedSegmentIndex = Parameters.filterDistance.rawValue
        distanceAmount.text = "\(Parameters.filterDistanceAmount) miles"
        distanceSlider.value = Float(Parameters.filterDistanceAmount)/maxDistance
    }
    
    private func formatBox(view: UIView) {
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1.0
        view.layer.cornerRadius = 5.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        spinner = Spinner(superview: view)
    }
    
    @objc private func upOrDownSwitchAction() {
    }
    
    enum DistanceFrom {
        case me
        case address
    }
    var distanceFrom: DistanceFrom {
        if distanceSwitch.selectedIndex == 0 {
            return .me
        }
        else {
            return .address
        }
    }
    
    // Change between sorting by distance from `me` and from the address given in the address field.
    @objc private func distanceSwitchAction() {
        addressContainer.isHidden = distanceFrom == .me
        
        if !distanceRadioButton.on {
            distanceRadioButton.setOn(true, animated: true)
        }
    }
    
    @objc private func cancelAction() {
        close()
    }
    
    internal override func close() {
        super.close()
        convertAddress?.cleanup()
    }
    
    @objc private func applyAction() {
        let newAscending = upOrDownSwitch.selectedIndex == 0 ? true : false

        switch radioButtonGroup.selectedCheckBox! {
        case distanceRadioButton:
            Parameters.orderFilter = OrderFilter.OrderFilterType.distance(ascending: newAscending)
            computeDistances()

        case alphabeticRadioButton:
            Parameters.orderFilter = OrderFilter.OrderFilterType.name(ascending: newAscending)
            delegate?.sortFilter(self)
            close()
            
        case ratingRadioButton:
            Parameters.orderFilter = OrderFilter.OrderFilterType.rating(ascending: newAscending)
            computeRatings()
            
            if Parameters.filterDistance == .on {
                // This also applies the sort to the UI.
                computeDistances()
            }
            else {
                delegate?.sortFilter(self)
                spinner.stop()
                close()
            }

        default:
            assert(false)
        }
    }
    
    private func computeDistances() {
        switch distanceFrom {
        case .me:
            spinner.start()

            // Recompute distances of all locations from our location. First, we need our location.
            animatingEarthImageView.isHidden = false
            Parameters.numberOfTimesLocationServicesFailed.intValue = 0
            ll = LatLong(delegate: self)
            
        case .address:
            let spaces = CharacterSet.whitespacesAndNewlines
            address.text = address.text.trimmingCharacters(in: spaces)
            if address.text.count > 0 {
                spinner.start()

                // Attempt to geocode the address
                convertAddress?.lookupAddress(address.text , withExitMethod: {
                })
            }
        }
    }
    
    private func computeRatings() {
        guard let locations = Location.fetchAllObjects() else {
            return
        }
        
        for location in locations {
            SortFilter.computeRating(forLocation: location)
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
        
        delegate?.sortFilter(self)
        spinner.stop()
        close()
    }
    
    @discardableResult
    static func showFrom(parentVC: UIViewController) -> SortFilter {
        let sortFilter = SortFilter(nibName: "SortFilter", bundle: nil)
        
        sortFilter.modalSize = CGSize(width: parentVC.view.frameWidth*0.9, height: parentVC.view.frameHeight*0.9)
        
        // I don't get the bar button items when I do this. Very odd.
        //sortFilter.modalSize = CGSize(width: sortFilter.view.frameWidth, height: sortFilter.view.frameHeight)
        
        sortFilter.modalParentVC = parentVC
        sortFilter.show()
        
        return sortFilter
    }
    
    @IBAction func alphabeticButtonAction(_ sender: Any) {
        if !alphabeticRadioButton.on {
            alphabeticRadioButton.setOn(true, animated: true)
        }
    }
    
    @IBAction func ratingButtonAction(_ sender: Any) {
        if !ratingRadioButton.on {
            ratingRadioButton.setOn(true, animated: true)
        }
    }
    
    @IBAction func distanceButtonAction(_ sender: Any) {
        if !distanceRadioButton.on {
            distanceRadioButton.setOn(true, animated: true)
        }
    }
    
    @IBAction func tryAainAction(_ sender: Any) {
        if let result = Parameters.FilterTryAgain(rawValue: tryAgainFilter.selectedSegmentIndex) {
            Parameters.filterTryAgain = result
        }
        else {
            Parameters.filterTryAgain = .off
        }
    }
    
    @IBAction func distanceFilterAction(_ sender: Any) {
        if let result = Parameters.FilterDistance(rawValue: distanceFilter.selectedSegmentIndex) {
            Parameters.filterDistance = result
        }
        else {
            Parameters.filterDistance = .off
        }
    }
    
    @IBAction func distanceSliderAction(_ sender: Any) {
        let distance = Int(distanceSlider.value*maxDistance)
        Parameters.filterDistanceAmount = distance
        distanceAmount.text = "\(distance) miles"
    }
}

extension SortFilter : LatLongDelegate {
    func userDidNotAuthorizeLocationServices() {
        animatingEarthImageView.isHidden = true
    }
    
    func haveReasonablyAccurateCoordinates() {
        Log.msg("haveReasonablyAccurateCoordinates")
    }
    
    func finishedAttemptingToObtainCoordinates() {
        animatingEarthImageView.isHidden = true
        
        Log.msg("finishedAttemptingToObtainCoordinates: ll: \(ll)")
        if ll.coords == nil {
            spinner.stop()
            Alert.show(fromVC: self, withTitle: "Could not obtain your current location.", message: "Are location services turned off?")
        }
        else {
            let coords = ll.coords!
            Log.msg("Coords from ll: \(coords)")
            Parameters.sortLocation = coords
            computeDistances(from: coords)
        }
    }
}

extension SortFilter : GeocodeAddressToLatLongDelegate {
    // This will be called if a failure occurs converting an address to
    // coordinates. An alert view will be given to the user before this is
    // called.
    func failureLookingupAddress() {
        Log.error("failureLookingupAddress")
        spinner?.stop()
    }

    // Called when successful; with the latitude and longitude of the successful conversion.
    func successLookingupAddress(_ latitude: Float, andLongitude longitude: Float) {
        let addressLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        Log.msg("Coords from ll: \(addressLocation)")
        Parameters.sortLocation = addressLocation
        computeDistances(from: addressLocation)
    }
}

#endif
