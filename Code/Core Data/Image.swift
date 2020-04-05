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

// Prior to v2.2 of the app, images didn't have UUID's. i.e., fileNames were not constructed from UUID's.

@objc(Image)
public class Image: NSManagedObject, Codable, EquatableObjects, UUIDCollisionAvoidance {
    static let UUID_KEY = "uuid"

    class func entityName() -> String {
        return "Image"
    }

    static func alreadyExists(uuid: Foundation.UUID) throws -> UUIDCollisionResult<Image> {
        if let image = try Self.fetchObject(withUUID: uuid.uuidString) {
            return .existsWithObject(image)
        }
        else {
            return .doesNotExist
        }
    }
    
    static func filePath(for fileName: String) -> String {
        return FileStorage.path(toItem: SMIdentifiers.LARGE_IMAGE_DIRECTORY) + "/" + fileName
    }
    
    var filePath: String {
        return Self.filePath(for: fileName!)
    }
    
    // Doesn't add uuid.
    class func newObject() -> Image {
        let image = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Image
        return image
    }
    
    class func fetchAllObjects(withUUID uuid: String) throws -> [Image]? {
        guard let fetchRequest = fetchRequestForObjects(withUUID: uuid) else {
            return nil
        }
                
        let moc = CoreData.sessionNamed(CoreDataExtras.sessionName).context
        guard let results = try moc.fetch(fetchRequest) as? [Image] else {
            return nil
        }
        
        if results.count == 0 {
            return nil
        }
        
        return results
    }
    
    class func fetchObject(withUUID uuid: String) throws -> Image? {
        guard let fetchRequest = fetchRequestForObjects(withUUID: uuid) else {
            return nil
        }
                
        let moc = CoreData.sessionNamed(CoreDataExtras.sessionName).context
        guard let results = try moc.fetch(fetchRequest) as? [Image] else {
            return nil
        }
        
        if results.count == 0 {
            return nil
        }
        
        return results[0]
    }
    
    private class func fetchRequestForObjects(withUUID uuid: String) -> NSFetchRequest<NSFetchRequestResult>? {
        var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
        
        fetchRequest = CoreData.sessionNamed(CoreDataExtras.sessionName).fetchRequest(
            withEntityName: self.entityName(), modifyingFetchRequestWith: { request in
            let predicate = NSPredicate(format: "(%K == %@)", UUID_KEY, uuid)
            request.predicate = predicate
        })

        if fetchRequest != nil {
            let sortDescriptor = NSSortDescriptor(key: UUID_KEY, ascending: true)
            fetchRequest!.sortDescriptors = [sortDescriptor]
        }
        
        return fetchRequest
    }
    
    static func createFileName(usingNewImageFileUUID newImageUUID: String) -> String {
        let newFileName = Identifiers.APP_NAME + "." + newImageUUID + "." + FileExtras.defaultFileExtension
        // e.g.,WhatDidILike.EA698671-D62D-46BA-94A1-C40C3DCFC7E1.jpg
        return newFileName
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
        case uuid
    }
        
    func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileName, forKey: .fileName)
        try container.encode(uuid, forKey: .uuid)
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
        let date = fileCreationDate(filePath: filePath)
        return [date].compactMap{$0}
    }
}

