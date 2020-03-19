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
public class Image: NSManagedObject, Codable, EquatableObjects {
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
    
    // MARK: Codable
    
    public required convenience init(from decoder: Decoder) throws {
        let context = CoreData.sessionNamed(CoreDataExtras.sessionName).context
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName(), in: context) else { fatalError() }
        self.init(entity: entity, insertInto: context)
        try decode(using: decoder)
    }
    
    enum CodingKeys: String, CodingKey {
        case fileName
    }
        
    func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileName, forKey: .fileName)
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
    
    static func equal(_ lhs: Image?, _ rhs: Image?) -> Bool {
        return lhs?.fileName == rhs?.fileName
    }
}

extension Image: Recommendations {
    var dates: [Date] {
        return [fileCreationDate(filePath: filePath)].compactMap{$0}
    }
}

extension Image: ImportExport {
    var largeImageFiles: [String] {
        return [fileName].compactMap{$0}
    }
}
