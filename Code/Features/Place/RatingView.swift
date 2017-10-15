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

protocol RatingManagedObject {
    // Value between 0 and 1-- 0 being completely unhappy.
    var rating: Float {get set}
    
    var meThem: Bool {get set}
    func save()
}

class RatingView: UIView, XibBasics {
    typealias ViewType = RatingView
    @IBOutlet private weak var rateView: EmojiRateView!
    @IBOutlet private weak var switchView: UIView!
    private let meThemSwitch = DGRunkeeperSwitch()
    private var rating: RatingManagedObject!
    @IBOutlet private weak var lockButton: UIButton!
    
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
        
        meThemSwitch.titles = ["Me", "Them"]
        meThemSwitch.selectedBackgroundColor = .white
        meThemSwitch.titleColor = .white
        meThemSwitch.backgroundColor = UIColor.lightGray
        meThemSwitch.selectedTitleColor = UIColor(red: 239.0/255.0, green: 95.0/255.0, blue: 49.0/255.0, alpha: 1.0)
        meThemSwitch.titleFont = UIFont(name: "HelveticaNeue-Medium", size: 17.0)
        meThemSwitch.frame = CGRect(x: 0, y: 0, width: switchView.frameWidth, height:switchView.frameHeight)
        meThemSwitch.addTarget(self, action: #selector(meThemSwitchAction), for: .valueChanged)
        switchView.addSubview(meThemSwitch)
        
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
    
    @objc private func meThemSwitchAction() {
        Log.msg("meThemSwitch: \(meThemSwitch.selectedIndex)")
        rating.meThem = meThemSwitch.selectedIndex == 0
        rating.save()
    }
    
    func setup(withRating rating: RatingManagedObject) {
        self.rating = rating
        let meThemIndex: Int = rating.meThem ? 0 : 1
        meThemSwitch.setSelectedIndex(meThemIndex, animated: false)
        ourRating = rating.rating
        rateView.rateValue = emojiRating
    }
    
    @IBAction func lockButtonAction(_ sender: Any) {
        enable(!rateView.isUserInteractionEnabled)
    }
    
    private func enable(_ enabled: Bool) {
        rateView.isUserInteractionEnabled = enabled
        lockButton.alpha = enabled ? 0.3 : 1.0
    }
}
