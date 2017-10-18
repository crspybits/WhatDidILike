//
//  RatingView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import DGRunkeeperSwitch
import TTGEmojiRate
import SMCoreLib

class RatingView: UIView, XibBasics {
    typealias ViewType = RatingView
    @IBOutlet private weak var rateView: EmojiRateView!
    @IBOutlet private weak var lockButton: UIButton!
    @IBOutlet weak var recommendedByContainer: UIView!
    @IBOutlet weak var recommendedByText: TextField!
    private var rating: Rating!
    @IBOutlet weak var stackView: UIStackView!
    private var originalStackViewSpacing:CGFloat!
    @IBOutlet weak var meThem: UISegmentedControl!
    @IBOutlet weak var again: UISegmentedControl!
    
    enum MeThemType : Int {
        case me = 0
        case them = 1
        case none = 2
        
        func toNSNumber() -> NSNumber? {
            switch self {
            case .me:
                return true
                
            case .none:
                return nil
                
            case .them:
                return false
            }
        }
        
        static func from(_ num: NSNumber?) -> MeThemType {
            if let num = num as? Bool {
                return num ? .me : .them
            }
            else {
                return .none
            }
        }
        
        func toSegmentValue() -> Int {
            switch self {
            case .me, .them:
                return rawValue
            case .none:
                return UISegmentedControlNoSegment
            }
        }
        
        static func fromSegmentValue(_ segment: Int) -> MeThemType {
            switch segment {
            case MeThemType.me.rawValue:
                return .me
            case MeThemType.them.rawValue:
                return .them
            case UISegmentedControlNoSegment:
                return .none
            default:
                assert(false)
            }
        }
    }
    
    enum AgainType : Int {
        case again = 0
        case notAgain = 1
        case none = 2
        
        func toNSNumber() -> NSNumber? {
            switch self {
            case .again:
                return true
                
            case .none:
                return nil
                
            case .notAgain:
                return false
            }
        }
        
        static func from(_ num: NSNumber?) -> AgainType {
            if let num = num as? Bool {
                return num ? .again : .notAgain
            }
            else {
                return .none
            }
        }
        
        func toSegmentValue() -> Int {
            switch self {
            case .again, .notAgain:
                return rawValue
            case .none:
                return UISegmentedControlNoSegment
            }
        }
        
        static func fromSegmentValue(_ segment: Int) -> AgainType {
            switch segment {
            case AgainType.again.rawValue:
                return .again
            case AgainType.notAgain.rawValue:
                return .notAgain
            case UISegmentedControlNoSegment:
                return .none
            default:
                assert(false)
            }
        }
    }
    
    private var _ourRating:Float = 0
    private var ourRating:Float {
        set {
            _ourRating = newValue
            _emojiRating = _ourRating * 5
        }
        get {
            return _ourRating
        }
    }
    
    private var _emojiRating:Float = 0
    private var emojiRating:Float{
        set {
            _emojiRating = newValue
            _ourRating = _emojiRating/5.0
        }
        get {
            return _emojiRating
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        originalStackViewSpacing = stackView.spacing
        
        Layout.format(textBox: recommendedByText)
        
        rateView.backgroundColor = UIColor.clear
        let best = UIColor(red: 0.0/255.0, green: 217.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        let worst = UIColor(red: 255.0/255.0, green: 0.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        rateView.rateColorRange = (from: worst, to: best)
        
        // Otherwise we get *alot* of changes to core data. And that just seems messy.
        let debounce = Debounce(type: .duration)
        debounce!.interval = 1
        
        rateView.rateValueChangeCallback = { emojiRatingValue in
            debounce!.queue() {[unowned self] in
                Log.msg("emojiRatingValue: \(emojiRatingValue)")
                self.emojiRating = emojiRatingValue
                self.rating.rating = self.ourRating
                self.rating.save()
            }
        }
        
        enable(false)
    }
    
    @discardableResult
    private func setupFromMeThem() -> MeThemType {
        let meThemType = MeThemType.fromSegmentValue(meThem.selectedSegmentIndex)
        recommendedByContainer.isHidden = meThemType == .me
        
        if meThemType == .me {
            // recommendedByContainer is hidden, so we can use more spacing
            stackView.spacing = originalStackViewSpacing * 2
        }
        else {
            stackView.spacing = originalStackViewSpacing
        }
        
        return meThemType
    }
    
    @IBAction func meThemControl(_ sender: Any) {
        var me: MeThemType!

        UIView.animate {
            me = self.setupFromMeThem()
        }

        rating.meThem = me.toNSNumber()
        rating.save()
    }
    
    @IBAction func againControl(_ sender: Any) {
        let againType = AgainType.fromSegmentValue(again.selectedSegmentIndex)
        rating.again = againType.toNSNumber()
        rating.save()
    }
    
    func setup(withRating rating: Rating) {
        let meThemType = MeThemType.from(rating.meThem)
        meThem.selectedSegmentIndex = meThemType.toSegmentValue()
        setupFromMeThem()
        
        let againType = AgainType.from(rating.again)
        again.selectedSegmentIndex = againType.toSegmentValue()
        
        self.rating = rating
        ourRating = rating.rating
        rateView.rateValue = emojiRating
        
        recommendedByText.text = rating.recommendedBy
        
        recommendedByText.save = { update in
            rating.recommendedBy = update
            rating.save()
        }
    }
    
    @IBAction func lockButtonAction(_ sender: Any) {
        enable(!rateView.isUserInteractionEnabled)
    }
    
    private func enable(_ enabled: Bool) {
        rateView.isUserInteractionEnabled = enabled
        lockButton.alpha = enabled ? 0.3 : 1.0
    }
}
