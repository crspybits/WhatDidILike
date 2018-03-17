//
//  SortyFilter.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/16/18.
//  Copyright © 2018 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import Presentr

class SortyFilter: UIViewController {
    @IBOutlet weak var sortingControls: UIView!
    var segmentedControl:SegmentedControl!
    
    let presenter: Presentr = {
        let width = ModalSize.full
        let height = ModalSize.fluid(percentage: 0.55)
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
    
    enum SortOrder : Int {
        case distance = 0
        case rating = 1
        case name = 2
    }
    
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
        
        segmentedControl = SegmentedControl(withComponents: [distance, rating, name])
        sortingControls.addSubview(segmentedControl)
        segmentedControl.select(componentIndex: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}
