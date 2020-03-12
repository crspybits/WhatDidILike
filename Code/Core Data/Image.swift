//
//  Image.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/3/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(Image)
public class Image: NSManagedObject {
    class func entityName() -> String {
        return "Image"
    }
    
    var filePath: String {
        return FileStorage.path(toItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY) + "/" + fileName!
    }
    
    class func newObject() -> Image {
        let image = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Image
        return image
    }
    
    func remove() {
        do {
            try FileManager.default.removeItem(atPath: filePath)
        } catch {
            Log.error("Could not delete file: \(filePath)")
        }
        
        // TODO: Remove any scaled images.
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}

extension Image: Recommendations {
    var dates: [Date] {
        return [fileCreationDate(filePath: filePath)].compactMap{$0}
    }
}
