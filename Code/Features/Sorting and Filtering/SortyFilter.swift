//
//  SortyFilter.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/16/18.
//  Copyright © 2018 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import Presentr
import DropDown

class SortyFilter: UIViewController {
    @IBOutlet weak var sortingControls: UIView!
    var sortControls:[Parameters.SortOrder: SortControl]!
    var segmentedControl:SegmentedControl!
    @IBOutlet weak var address: TextView!
    @IBOutlet weak var distanceButton: UIButton!
    @IBOutlet weak var locationControl: UISegmentedControl!
    @IBOutlet weak var tryAgainButton: UIButton!
    let tryAgainDropdown = DropDown()
    let distanceDropdown = DropDown()
    
    let presenter: Presentr = {
        let width = ModalSize.full
        let height = ModalSize.custom(size: 410)
        let center = ModalCenterPosition.customOrigin(origin: CGPoint(x: 0, y: 70))
        let customType = PresentationType.custom(width: width, height: height, center: center)

        let customPresenter = Presentr(presentationType: customType)
        customPresenter.transitionType = .coverVerticalFromTop
        customPresenter.dismissTransitionType = .crossDissolve
        customPresenter.roundCorners = false
        customPresenter.backgroundOpacity = 0.5
        customPresenter.dismissOnSwipe = true
        customPresenter.dismissOnSwipeDirection = .top
    
        return customPresenter
    }()
    
    @IBOutlet weak var sortOrder: UISegmentedControl!
    
    static func show(fromParentVC parentVC: UIViewController) {
        let sortyFilter = SortyFilter()
        parentVC.customPresentViewController(sortyFilter.presenter, viewController: sortyFilter, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        let distance = SortControl.create()!
        distance.setup(withName: "Distance")
        let rating = SortControl.create()!
        rating.setup(withName: "Rating")
        let name = SortControl.create()!
        name.setup(withName: "Name")
        
        sortControls = [.distance: distance, .rating: rating, .name: name]
        let components = [distance, rating, name]
        
        segmentedControl = SegmentedControl(withComponents: components)
        segmentedControl.delegate = self
        sortingControls.addSubview(segmentedControl)
        
        address.save = { update in
            Parameters.orderAddress = update
        }
        
        segmentedControl.select(componentIndex: UInt(Parameters.sortingOrder.rawValue))
        distance.currState = Parameters.distanceAscending ? .ascending : .descending
        rating.currState = Parameters.ratingAscending ? .ascending : .descending
        name.currState = Parameters.nameAscending ? .ascending : .descending
        address.text = Parameters.orderAddress
        locationControl.selectedSegmentIndex = Parameters.location.rawValue
        tryAgainButton.setTitle(Parameters.tryAgainFilter.rawValue, for: .normal)
        distanceButton.setTitle(Parameters.distanceFilter.rawValue, for: .normal)
        
        setupDropdowns()
    }
    
    private func setupDropdowns() {
        tryAgainDropdown.anchorView = tryAgainButton
        tryAgainDropdown.dismissMode = .automatic
        tryAgainDropdown.direction = .any
        
        tryAgainDropdown.selectionAction = { [weak self] (index, item) in
            self?.tryAgainButton.setTitle(item, for: .normal)
            if let result = Parameters.TryAgainFilter(rawValue: item) {
                Parameters.tryAgainFilter = result
            }
            self?.tryAgainDropdown.hide()
        }

        tryAgainDropdown.dataSource = [Parameters.TryAgainFilter.dontUse.rawValue, Parameters.TryAgainFilter.again.rawValue, Parameters.TryAgainFilter.notAgain.rawValue]
        
        distanceDropdown.anchorView = distanceButton
        distanceDropdown.dismissMode = .automatic
        distanceDropdown.direction = .any
        
        distanceDropdown.selectionAction = { [weak self] (index, item) in
            self?.distanceButton.setTitle(item, for: .normal)
            if let result = Parameters.DistanceFilter(rawValue: item) {
                Parameters.distanceFilter = result
            }
            self?.distanceDropdown.hide()
        }

        distanceDropdown.dataSource = [Parameters.DistanceFilter.dontUse.rawValue, Parameters.DistanceFilter.use.rawValue]
    }
    
    @IBAction func tryAgainAction(_ sender: Any) {
        tryAgainDropdown.show()
    }

    @IBAction func distanceAction(_ sender: Any) {
        distanceDropdown.show()
    }
    
    @IBAction func locationControlAction(_ sender: Any) {
        if let result = Parameters.Location(rawValue: locationControl.selectedSegmentIndex) {
            Parameters.location = result
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

extension SortyFilter : SegmentedControlDelegate {
    func segmentedControlChanged(_ segmentedControl: SegmentedControl, selectionToIndex index: UInt) {
    
        guard let sortOrder = Parameters.SortOrder(rawValue: Int(index)),
            let sortControl = sortControls[sortOrder] else {
            return
        }
        
        let ascending = sortControl.currState == .ascending
        
        Parameters.sortingOrder = sortOrder
        
        switch sortOrder {
        case .distance:
            Parameters.distanceAscending = ascending

        case .rating:
            Parameters.ratingAscending = ascending

        case .name:
            Parameters.nameAscending = ascending
        }
    }
}
