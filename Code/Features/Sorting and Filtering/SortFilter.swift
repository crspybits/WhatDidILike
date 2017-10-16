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
    @IBOutlet private weak var address: UITextView!
    @IBOutlet weak var addressContainer: UIView!
    var delegate:SortFilterDelegate?
    @IBOutlet weak var alphabeticContainer: UIView!
    private var ll:LatLong!
    @IBOutlet weak var distanceRadioButton: BEMCheckBox!
    @IBOutlet weak var alphabeticRadioButton: BEMCheckBox!
    private var radioButtonGroup:BEMCheckBoxGroup!
    
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
        
        distanceSwitchAction()
        
        radioButtonGroup = BEMCheckBoxGroup(checkBoxes: [distanceRadioButton, alphabeticRadioButton])
        
        switch Parameters.orderFilter {
        case .distance:
            radioButtonGroup.selectedCheckBox = distanceRadioButton
            
        case .name:
            radioButtonGroup.selectedCheckBox = alphabeticRadioButton
        }
        
        radioButtonGroup.mustHaveSelection = true
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
    
    @objc private func distanceSwitchAction() {
        addressContainer.isHidden = distanceSwitch.selectedIndex == 0
        
        if !distanceRadioButton.on {
            distanceRadioButton.setOn(true, animated: true)
        }
    }
    
    @objc private func cancelAction() {
        close()
    }
    
    @objc private func applyAction() {
        let newAscending = upOrDownSwitch.selectedIndex == 0 ? true : false

        switch radioButtonGroup.selectedCheckBox! {
        case distanceRadioButton:
            Parameters.orderFilter = OrderFilter.OrderFilterType.distance(ascending: newAscending)
            
            spinner.start()
            
            // Recompute distances of all locations from our location. First, we need our location.
            animatingEarthImageView.isHidden = false
            Parameters.numberOfTimesLocationServicesFailed.intValue = 0
            ll = LatLong(delegate: self)
            
        case alphabeticRadioButton:
            Parameters.orderFilter = OrderFilter.OrderFilterType.name(ascending: newAscending)
            delegate?.sortFilter(self)
            close()

        default:
            assert(false)
        }
    }
    
    private func computeDistances(from: CLLocation) {
        guard let locations = Location.fetchAllObjects() else {
            return
        }
        
        for location in locations {
            if let clLocation = location.location {
                location.sortingDistance = Float(clLocation.distance(from: from))
            }
            else {
                location.sortingDistance = Float.greatestFiniteMagnitude
            }
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
}

extension SortFilter : LatLongDelegate {
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
            computeDistances(from: coords)
        }
    }
}
