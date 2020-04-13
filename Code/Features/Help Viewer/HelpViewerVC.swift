//
//  HelpViewerVC.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 4/12/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import WebKit

class HelpViewerVC: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    private var spinner:Spinner?
    private var helpFileName: String!
    private var helpFileExtension: String!

    // Expects filename in form "Name.Extension". E.g., "backupHelp.html". File must be in app bundle.
    static func create(toViewHelpFile helpFile: String) -> HelpViewerVC? {
        let storyboard = UIStoryboard(name: "HelpViewerVC", bundle: nil)
        
        guard let result = storyboard.instantiateViewController(withIdentifier: "HelpViewerVC") as? HelpViewerVC else {
            return nil
        }
        
        let fileNameParts = helpFile.split(separator: ".")
        guard fileNameParts.count == 2 else {
            return nil
        }
        
        result.helpFileName = String(fileNameParts[0])
        result.helpFileExtension = String(fileNameParts[1])

        return result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Help"
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        spinner = Spinner(superview: webView)
        
        if let url = Bundle.main.url(forResource: "backupHelp", withExtension: "html")  {
            spinner?.start()
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

extension HelpViewerVC: WKUIDelegate {
}

extension HelpViewerVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        spinner?.stop()
    }
}
