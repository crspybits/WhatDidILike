//
//  Comment.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Comment)
public class Comment: BaseObject, ImagesManagedObject, Codable, EquatableObjects {
    override class func entityName() -> String {
        return "Comment"
    }
    
    override class func newObject() throws -> Comment {
        let newComment = try super.newObject() as! Comment
        newComment.rating = Rating.newObject()
        return newComment
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case creationDate
        case modificationDate
        case comment
        case images
        case rating
        
        // Not including `item` because it's the parent.
    }
        
    override func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate) as NSDate?
        modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate) as NSDate?
        comment = try container.decodeIfPresent(String.self, forKey: .comment)

        if let images = try container.decodeIfPresent([Image].self, forKey: .images) {
            addToImages(NSOrderedSet(array: images))
        }
        
        rating = try container.decodeIfPresent(Rating.self, forKey: .rating)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let creationDate = creationDate as Date? {
            try container.encode(creationDate, forKey: .creationDate)
        }
        
        if let modificationDate = modificationDate as Date? {
            try container.encode(modificationDate, forKey: .modificationDate)
        }
        
        try container.encode(comment, forKey: .comment)
        
        if let images = images?.array as? [Image] {
            try container.encode(images, forKey: .images)
        }
        
        try container.encode(rating, forKey: .rating)
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func remove() {
        for imageObj in images! {
            let image = imageObj as! Image
            image.remove()
        }
        
        rating!.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
    
    static func equal(_ lhs: Comment?, _ rhs: Comment?) -> Bool {
        return lhs?.comment == rhs?.comment &&
            Image.equal(lhs?.images?.array as? [Image], rhs?.images?.array as? [Image]) &&
            Item.equal(lhs?.item, rhs?.item) &&
            Rating.equal(lhs?.rating, rhs?.rating)
    }
}

extension Comment {
    override var dates: [Date] {
        var result = [Date]()
        
        if let images = images {
            for image in images {
                if let image = image as? Image {
                    result += image.dates
                }
            }
        }
        
        if let rating = rating {
            result += rating.dates
        }
        
        return super.dates + result
    }
}

extension Comment: ImportExport {
    var largeImages: [Image] {
        if let images = self.images?.array as? [Image] {
            return images
        }
        else {
            return []
        }
    }
}
