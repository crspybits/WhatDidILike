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
    private var imagesOwnerObj: ImagesManagedObject!
    private var localSource = [ImageSource]()
    private var smAcquireImage:SMAcquireImage!
    
    func setup(withParentVC vc: UIViewController, andImagesObj imagesOwnerObj: ImagesManagedObject) {
        self.vc = vc
        self.imagesOwnerObj = imagesOwnerObj
        
        // See also https://stackoverflow.com/questions/37574689/how-to-load-image-from-local-path-ios-swift-by-path
        
        if let images = imagesOwnerObj.images {
            for obj in images {
                let imageCoreData = obj as! Image
                let fileURL = FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY + "/" + imageCoreData.fileName!)
                addImage(from: fileURL!)
            }
        }

        images.pageControlPosition = PageControlPosition.underScrollView
        images.pageControl.currentPageIndicatorTintColor = UIColor.lightGray
        images.pageControl.pageIndicatorTintColor = UIColor.black
        images.contentScaleMode = UIViewContentMode.scaleAspectFill
        
        images.setImageInputs(localSource)
        Log.msg("Number of images: \(localSource.count)")

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        images.addGestureRecognizer(recognizer)
    }
    
    private func addImage(from url: URL) {
        do {
            let imageData = try Data(contentsOf: url)
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
    
    @objc private func didTap() {
        images.presentFullScreenController(from: vc)
    }
    
    @IBAction private func addImage(_ sender: Any) {
        smAcquireImage = SMAcquireImage(withParentViewController: vc)
        smAcquireImage.delegate = self
        smAcquireImage.showAlert(fromView: self)
    }
}

extension ImagesView : SMAcquireImageDelegate {
    func smAcquireImageURLForNewImage(_ acquireImage:SMAcquireImage) -> SMRelativeLocalURL {
        let fileExtras = FileExtras()
        fileExtras.filePrefix = Identifiers.APP_NAME
        fileExtras.directoryPathFromDocuments = SMIdentifiers.LARGE_IMAGE_DIRECTORY
        return fileExtras.newURLForImage()
    }

    func smAcquireImage(_ acquireImage:SMAcquireImage, newImageURL: SMRelativeLocalURL, mimeType:String) {
        let newImageObj = Image.newObject()
        newImageObj.fileName = newImageURL.lastPathComponent
        imagesOwnerObj.addToImages(newImageObj)
        newImageObj.save()
        
        addImage(from: newImageURL as URL)
        images.setImageInputs(localSource)
        
        smAcquireImage = nil
    }
}
