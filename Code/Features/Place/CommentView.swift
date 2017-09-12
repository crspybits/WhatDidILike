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
    let rating = RatingView.create()!

    override func awakeFromNib() {
        super.awakeFromNib()
        Layout.format(textBox: comment)
        
        rating.frameWidth = ratingContainer.frameWidth
        ratingContainer.addSubview(rating)
    }
    
    func setup(withComment comment: Comment) {
        self.comment.text = comment.comment
    }
}
