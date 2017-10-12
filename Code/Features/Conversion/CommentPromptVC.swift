//
//  CommentPromptVC.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/11/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib

class CommentPromptVC: SMModal {
    var single: (()->())?
    var multiple: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }
    
    static func createWith(parentVC: UIViewController) ->  CommentPromptVC {
        let prompt = CommentPromptVC(nibName: "CommentPromptVC", bundle: nil)
        prompt.hidesNavBar = true
        prompt.modalSize = prompt.view.frameSize
        prompt.modalParentVC = parentVC
        return prompt
    }
    
    override func show() {
        super.show()
        
        // A bit hacky -- this property is only available after the modal is shown.
        changeFrameTd.allowBackgroundTapDismiss = false
    }
    
    @IBAction func singleCommentAction(_ sender: Any) {
        Log.msg("single")
        single?()
    }
    
    @IBAction func multipleCommentAction(_ sender: Any) {
        Log.msg("multiple")
        multiple?()
    }
}
