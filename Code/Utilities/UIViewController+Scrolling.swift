//
//  UIViewController+Scrolling.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/10/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import UIKit
import SMCoreLib

extension UIViewController {
    func scrollingSetup(selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    // `scrollViewBottom`: A constraint on the bottom of the scroll view, so this can move it up.
    // `titleAdjustment` is a weee bit of a hack to show the title that shows up beneath a text view/text field.
    func scrollingKeyboardWillChangeFrame(notification:NSNotification, scrollViewBottom: NSLayoutConstraint, scrollView:UIScrollView, showView: UIView, titleAdjustment: CGFloat = 20) {
    
        let kbFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        let kbWindowIntersectionFrame = view.window!.bounds.intersection(kbFrame)
        let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        // I'm always having problems with coordindate space conversions. This helped: https://stackoverflow.com/questions/3219331/convert-a-uiview-origin-point-to-its-window-coordinate-system
        var showFrame = scrollView.convert(showView.frame, from: showView.superview!)
        showFrame.size.height += titleAdjustment
        
        // I'm not sure why the constant needs to be negative now-- this wasn't the way it was before the safe area constraints...
        scrollViewBottom.constant = -kbWindowIntersectionFrame.size.height
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            
            if kbWindowIntersectionFrame.size.height > 0 {
                scrollView.scrollRectToVisible(showFrame, animated: false)
            }
        }
    }
    
    func scrollingTearDown() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
}
