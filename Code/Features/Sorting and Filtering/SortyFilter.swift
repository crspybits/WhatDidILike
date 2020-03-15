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

// An explicit tap of the Cancel button will close the modal and discard any changes in the UI. Tapping "Apply" or dismissing by pressing outside of the window will apply any changes.

protocol SortyFilterDelegate : class {
    func sortyFilter(reset: SortyFilter)
    func sortyFilter(sortFilterByParameters: SortyFilter)
}

private class SortyFilterState {
    var sortingOrder: Parameters.SortOrder
    var distanceAscending:Bool
    var suggestAscending:Bool
    var nameAscending:Bool
    
    var location: Parameters.Location
    var address: String
    
    var tryAgainFilter:Parameters.TryAgainFilter
    var distanceFilter:Parameters.DistanceFilter
    var distance: Int
    
    init() {
        sortingOrder = Parameters.sortingOrder
        distanceAscending = Parameters.distanceAscending
        suggestAscending = Parameters.suggestAscending
        nameAscending = Parameters.nameAscending
        
        location = Parameters.location
        address = Parameters.orderAddress
        
        tryAgainFilter = Parameters.tryAgainFilter
        distanceFilter = Parameters.distanceFilter
        distance = Parameters.distanceFilterAmount
    }
    
    func save() {
        Parameters.sortingOrder = sortingOrder
        Parameters.distanceAscending = distanceAscending
        Parameters.suggestAscending = suggestAscending
        Parameters.nameAscending = nameAscending
    
        Parameters.location = location
        Parameters.orderAddress = address
    
        Parameters.tryAgainFilter = tryAgainFilter
        Parameters.distanceFilter = distanceFilter
        Parameters.distanceFilterAmount = distance
    }
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
    @IBOutlet weak var tryAgainView: UIView!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var distance: UILabel!
    let maxDistance:Float = 50
    private var spinner: Spinner!
    private var animatingEarthImageView:FLAnimatedImageView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var navBar: UINavigationBar!
    private var apply:ApplySortyFilter!
    var delegate:SortyFilterDelegate!
    
    private let state = SortyFilterState()

    static let modalHeight = ModalSize.custom(size: 455)
    static let modalWidth = ModalSize.full
    
    static let customTypePortrait: PresentationType = {
        let center = ModalCenterPosition.customOrigin(origin: CGPoint(x: 0, y: 0))
        let customType = PresentationType.custom(width: SortyFilter.modalWidth, height: SortyFilter.modalHeight, center: center)
        return customType
    }()
    
    let presenter: Presentr = {
        let customPresenter = Presentr(presentationType: SortyFilter.customTypePortrait)
        customPresenter.transitionType = .coverVerticalFromTop
        customPresenter.dismissTransitionType = .crossDissolve
        customPresenter.roundCorners = false
        customPresenter.backgroundOpacity = 0.5
        customPresenter.dismissOnSwipeDirection = .top
        customPresenter.dismissOnSwipe = true
        return customPresenter
    }()
    
    @IBOutlet weak var sortOrder: UISegmentedControl!
    
    static func show(fromParentVC parentVC: UIViewController, usingDelegate delegate: SortyFilterDelegate) {
        let sortyFilter = SortyFilter()
        sortyFilter.delegate = delegate
        parentVC.customPresentViewController(sortyFilter.presenter, viewController: sortyFilter, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .sortyFilterBackground
        navBar.barTintColor = .sortyFilterBackground
        
        tryAgainView.backgroundColor = .dropDownBackground
        distanceView.backgroundColor = .dropDownBackground

        let distance = SortControl.create()!
        distance.setup(withName: "Distance")
        let suggest = SortControl.create()!
        suggest.setup(withName: "Suggest")
        let name = SortControl.create()!
        name.setup(withName: "Name")
        
        sortControls = [.distance: distance, .suggest: suggest, .name: name]
        let components = [distance, suggest, name]
        
        segmentedControl = SegmentedControl(withComponents: components)
        segmentedControl.delegate = self
        sortingControls.addSubview(segmentedControl)
        
        address.save = {[unowned self] update in
            let spaces = CharacterSet.whitespacesAndNewlines
            self.state.address = update.trimmingCharacters(in: spaces)
        }
        
        segmentedControl.select(componentIndex: UInt(state.sortingOrder.rawValue))
        distance.currState = state.distanceAscending ? .ascending : .descending
        suggest.currState = state.suggestAscending ? .ascending : .descending
        name.currState = state.nameAscending ? .ascending : .descending
        address.text = state.address
        locationControl.selectedSegmentIndex = state.location.rawValue
        tryAgainButton.setTitle(state.tryAgainFilter.rawValue, for: .normal)
        distanceButton.setTitle(state.distanceFilter.rawValue, for: .normal)
        self.distance.text = formatMiles(state.distance)
        distanceSlider.value = Float(state.distance)/maxDistance
        
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
                self?.state.tryAgainFilter = result
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
                self?.state.distanceFilter = result
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
            state.location = result
        }
    }
    
    @IBAction func distanceSliderAction(_ sender: Any) {
        let d = Int(distanceSlider.value * maxDistance)
        state.distance = d
        distance.text = formatMiles(d)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func applyAction(_ sender: Any) {
        applySortyFilter()
    }
    
    private func applySortyFilter() {
        spinner.start()
        state.save()
        
        // Without the following `DispatchQueue.main.asyncAfter`, the spinner doesn't start spinning for too long (maybe 1 second). And the user gets the sense that their dismiss of the SortyFilter modal hasn't taken effect. The same delay, and UX issue, occurs even if I do a layoutIfNeeded on the superview of the spinner.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            self.apply.apply() {[unowned self] in
                self.spinner.stop()
            }
        }
    }
}

extension SortyFilter : SegmentedControlDelegate {
    func segmentedControlChanged(_ segmentedControl: SegmentedControl, selectionToIndex index: UInt) {
    
        guard let sortOrder = Parameters.SortOrder(rawValue: Int(index)),
            let sortControl = sortControls[sortOrder] else {
            return
        }
        
        let ascending = sortControl.currState == .ascending
        
        state.sortingOrder = sortOrder
        
        switch sortOrder {
        case .distance:
            state.distanceAscending = ascending

        case .suggest:
            state.suggestAscending = ascending

        case .name:
            state.nameAscending = ascending
        }
    }
}

extension SortyFilter : ApplySortyFilterDelegate {
    func sortyFilter(reset: ApplySortyFilter) {
        print("reset: delegate: \(String(describing: delegate))")
        delegate?.sortyFilter(reset: self)
    }

    func sortyFilter(sortFilterByParameters: ApplySortyFilter) {
        print("sortFilterByParameters: delegate: \(String(describing: delegate))")
        delegate?.sortyFilter(sortFilterByParameters: self)
        dismiss(animated: true, completion: nil)
    }
    
    func sortyFilter(startUsingLocationServices:ApplySortyFilter) {
        animatingEarthImageView.isHidden = false
    }
    
    func sortyFilter(stopUsingLocationServices:ApplySortyFilter) {
        animatingEarthImageView.isHidden = true
    }
}

extension SortyFilter: PresentrDelegate {
    func presentrShouldDismiss(keyboardShowing: Bool) -> Bool {
        applySortyFilter()
        return false
    }
}
