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
import FLAnimatedImage

protocol SortyFilterDelegate : class {
    func sortyFilter(_ sortFilterByParameters: SortyFilter)
}

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
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var distance: UILabel!
    let maxDistance:Float = 50
    private var spinner: Spinner!
    private var animatingEarthImageView:FLAnimatedImageView!
    @IBOutlet weak var navItem: UINavigationItem!
    private var apply:ApplySortyFilter!
    var delegate:SortyFilterDelegate!
    
    let presenter: Presentr = {
        let width = ModalSize.full
        let height = ModalSize.custom(size: 402)
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
            let spaces = CharacterSet.whitespacesAndNewlines
            Parameters.orderAddress = update.trimmingCharacters(in: spaces)
        }
        
        segmentedControl.select(componentIndex: UInt(Parameters.sortingOrder.rawValue))
        distance.currState = Parameters.distanceAscending ? .ascending : .descending
        rating.currState = Parameters.ratingAscending ? .ascending : .descending
        name.currState = Parameters.nameAscending ? .ascending : .descending
        address.text = Parameters.orderAddress
        locationControl.selectedSegmentIndex = Parameters.location.rawValue
        tryAgainButton.setTitle(Parameters.tryAgainFilter.rawValue, for: .normal)
        distanceButton.setTitle(Parameters.distanceFilter.rawValue, for: .normal)
        self.distance.text = formatMiles(Parameters.distanceFilterAmount)
        distanceSlider.value = Float(Parameters.distanceFilterAmount)/maxDistance
        
        setupDropdowns()
        
        let (imageView, gpsBarButton) = GPSExtras.spinner()
        animatingEarthImageView = imageView
        
        let apply = UIBarButtonItem(title: "Apply", style: .plain, target: self, action: #selector(applyAction))
        navItem.rightBarButtonItems = [apply, gpsBarButton]
        
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAction))
        navItem.leftBarButtonItem = cancel
        
        Layout.format(textBox: address)
        address.autocapitalizationType = .sentences
        address.autocorrectionType = .no
        
        self.apply = ApplySortyFilter(withViewController: self)
        self.apply.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        spinner = Spinner(superview: view)
    }
    
    private func formatMiles(_ miles: Int) -> String {
        return "\(miles) miles"
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
    
    @IBAction func distanceSliderAction(_ sender: Any) {
        let d = Int(distanceSlider.value * maxDistance)
        Parameters.distanceFilterAmount = d
        distance.text = formatMiles(d)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func applyAction(_ sender: Any) {
        apply.apply()
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

extension SortyFilter : ApplySortyFilterDelegate {
    func sortyFilter(sortFilterByParameters: ApplySortyFilter) {
        delegate?.sortyFilter(self)
    }
    
    func sortyFilter(startUsingLocationServices:ApplySortyFilter) {
        spinner.start()
        animatingEarthImageView.isHidden = false
    }
    
    func sortyFilter(stopUsingLocationServices:ApplySortyFilter) {
        spinner.stop()
        animatingEarthImageView.isHidden = true
    }
}
