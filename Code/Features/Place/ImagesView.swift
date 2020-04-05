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

private class WDILImageSource : ImageSource {
    let imageObj:Image
    
    public init(image: UIImage, imageObj:Image) {
        self.imageObj = imageObj
        super.init(image: image)
    }
}

class ImagesView: UIView, XibBasics {
    typealias ViewType = ImagesView
    @IBOutlet weak var images: ImageSlideshow!
    @IBOutlet weak var lowerLeftLabel: UILabel!
    private weak var vc: UIViewController!
    private var imagesOwnerObj: ImagesManagedObject!
    private var localSource = [WDILImageSource]()
    private var smAcquireImage:SMAcquireImage!
    private var newImageUUID: String!
    
    func setup(withParentVC vc: UIViewController, andImagesObj imagesOwnerObj: ImagesManagedObject) {
        self.vc = vc
        self.imagesOwnerObj = imagesOwnerObj
        
        images.showActions = true
        images.fullScreenSlideshowViewControllerDelegate = self
        
        // See also https://stackoverflow.com/questions/37574689/how-to-load-image-from-local-path-ios-swift-by-path
        
        if let images = imagesOwnerObj.images {
            for obj in images {
                let imageCoreData = obj as! Image
                let fileURL = FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY + "/" + imageCoreData.fileName!)
                addImage(from: fileURL!, imageObj: imageCoreData)
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
    
    private func addImage(from url: URL, imageObj: Image) {
        do {
            let imageData = try Data(contentsOf: url)
            if let image = UIImage(data: imageData) {
                let source = WDILImageSource(image: image, imageObj: imageObj)
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
        if let count = imagesOwnerObj?.images?.count, count > 0 {            
            images.presentFullScreenController(from: vc)
        }
    }
    
    @IBAction private func addImage(_ sender: Any) {
        do {
            newImageUUID = try Image.realUUID()
        } catch let error {
            let alert = UIAlertController(title: "Alert!", message: "Problem adding image: \(error)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            vc?.present(alert, animated: true, completion: nil)
            return
        }
        
        smAcquireImage = SMAcquireImage(withParentViewController: vc)
        smAcquireImage.delegate = self
        smAcquireImage.showAlert(fromView: self)
    }
    
    deinit {
        Log.msg("deinit")
    }
}

extension ImagesView : SMAcquireImageDelegate {
    func smAcquireImageURLForNewImage(_ acquireImage:SMAcquireImage) -> SMRelativeLocalURL {
        let directoryURL = FileStorage.url(ofItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY)
        FileStorage.createDirectoryIfNeeded(directoryURL)
        
        // Prior to v2.2
        // let newFileName = FileStorage.createTempFileName(inDirectory: directoryURL?.path, withPrefix: Identifiers.APP_NAME, andExtension: FileExtras.defaultFileExtension)
        // e.g., WhatDidILike.qQ18P.jpg
        
        // v2.2 and after
        let newFileName = Image.createFileName(usingNewImageFileUUID: newImageUUID)
        // e.g.,WhatDidILike.EA698671-D62D-46BA-94A1-C40C3DCFC7E1.jpg

        return SMRelativeLocalURL(withRelativePath: SMIdentifiers.LARGE_IMAGE_DIRECTORY + "/" + newFileName, toBaseURLType: .documentsDirectory)!
    }

    func smAcquireImage(_ acquireImage:SMAcquireImage, newImageURL: SMRelativeLocalURL, mimeType:String) {
        let newImageObj = Image.newObject()
        newImageObj.uuid = newImageUUID
        newImageObj.fileName = newImageURL.lastPathComponent
        imagesOwnerObj.addToImages(newImageObj)
        newImageObj.save()
        
        addImage(from: newImageURL as URL, imageObj: newImageObj)
        images.setImageInputs(localSource)
        
        smAcquireImage = nil
    }
}

extension ImagesView : FullScreenSlideshowViewControllerDelegate {
    func deleteImage(_ controller: FullScreenSlideshowViewController, imageToDelete: InputSource) {
        guard let imageSource = imageToDelete as? WDILImageSource else {
            Log.error("Yark: ImageSource did not have type WDILImageSource")
            return
        }
        
        imageSource.imageObj.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}
