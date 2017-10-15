//
//  CommentView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit

class CommentView: UIView, XibBasics {
    typealias ViewType = CommentView
    @IBOutlet weak var commentImagesContainer: UIView!
    @IBOutlet weak var ratingContainer: UIView!
    @IBOutlet weak var comment: TextView!
    private let rating = RatingView.create()!
    private let images = ImagesView.create()!
    @IBOutlet weak var removeButton: UIButton!
    var removeComment:(()->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: comment)
        
        rating.frameWidth = ratingContainer.frameWidth
        ratingContainer.addSubview(rating)
        
        images.frameWidth = commentImagesContainer.frameWidth
        commentImagesContainer.addSubview(images)
    }
    
    func setup(withComment comment: Comment, andParentVC vc: UIViewController) {
        self.comment.text = comment.comment
        rating.setup(withRating: comment)
        images.setup(withParentVC:vc, andImagesObj: comment)
        
        removeButton.isHidden = Parameters.commentStyle == .single
    }
    
    @IBAction func removeCommentAction(_ sender: Any) {
        removeComment?()
    }
}
