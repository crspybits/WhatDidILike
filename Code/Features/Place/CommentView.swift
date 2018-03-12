//
//  CommentView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib

class CommentView: UIView, XibBasics {
    typealias ViewType = CommentView
    @IBOutlet weak var bottom: NSLayoutConstraint!
    @IBOutlet weak var commentImagesContainer: UIView!
    @IBOutlet weak var ratingContainer: UIView!
    @IBOutlet weak var comment: TextView!
    private let rating = RatingView.create()!
    private let images = ImagesView.create()!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var separator: UIView!
    var removeComment:(()->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: comment)
        comment.autocapitalizationType = .sentences

        rating.frameWidth = ratingContainer.frameWidth
        ratingContainer.addSubview(rating)
        
        images.frameWidth = commentImagesContainer.frameWidth
        commentImagesContainer.addSubview(images)
        
        images.lowerLeftLabel.text = "Comment pictures"
        
        Layout.format(comment: self)
    }
    
    func setup(withComment comment: Comment, andParentVC vc: UIViewController) {
        self.comment.text = comment.comment
        rating.setup(withRating: comment.rating!)
        images.setup(withParentVC:vc, andImagesObj: comment)
        
        removeButton.isHidden = Parameters.commentStyle == .single
        
        // Assumes images are positioned at the bottom of the CommentView.
        if Parameters.commentStyle == .single {
            // This removes extra area needed for the removeButton and also makes the corner rounding look better.
            frameHeight -= bottom.constant
            bottom.constant = 0
        }
    }
    
    @IBAction func removeCommentAction(_ sender: Any) {
        removeComment?()
    }
    
    deinit {
        Log.msg("deinit")
    }
}
