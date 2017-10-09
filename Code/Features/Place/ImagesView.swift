//
//  ImagesView.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/8/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import UIKit
import SMCoreLib
import ImageSlideshow

protocol ImagesManagedObject {
    // ordered set of Image's
    var images: NSOrderedSet? {get set}
    
    func addToImages(_ value: Image)
    func removeFromImages(_ value: Image)
    func save()
}

class ImagesView: UIView, XibBasics {
    typealias ViewType = ImagesView
    @IBOutlet weak var images: ImageSlideshow!
    private weak var vc: UIViewController!
    private var imagesObj: ImagesManagedObject!
    
    func setup(withParentVC vc: UIViewController, andImagesObj imagesObj: ImagesManagedObject) {
        self.vc = vc
        self.imagesObj = imagesObj
        
        var localSource = [ImageSource]()
        if let images = imagesObj.images {
            for obj in images {
                let imageCoreData = obj as! Image
                let fileURL = FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY + "/" + imageCoreData.fileName!)
                do {
                    let imageData = try Data(contentsOf: fileURL!)
                    if let image = UIImage(data: imageData) {
                        let source = ImageSource(image: image)
                        localSource.append(source)
                    }
                    else {
                        Log.error("Error converting image data to UIImage!")
                    }
                } catch {
                    Log.error("Error loading image : \(error)")
                }
            }
        }

        images.backgroundColor = UIColor.clear
        images.pageControlPosition = PageControlPosition.underScrollView
        images.pageControl.currentPageIndicatorTintColor = UIColor.lightGray
        images.pageControl.pageIndicatorTintColor = UIColor.black
        images.contentScaleMode = UIViewContentMode.scaleAspectFill
        
        images.setImageInputs(localSource)
        Log.msg("Number of images: \(localSource.count)")

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        images.addGestureRecognizer(recognizer)
    }
    
    @objc private func didTap() {
        images.presentFullScreenController(from: vc)
    }
    
    @IBAction private func addImage(_ sender: Any) {
    }
}
