//
//  Item.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Item)
public class Item: BaseObject, Codable, EquatableObjects {
    override class func entityName() -> String {
        return "Item"
    }
    
    override class func newObject() throws -> Item {
        return try super.newObject() as! Item
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case creationDate
        case modificationDate
        case name
        case comments
    }
    
    override func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate) as NSDate?
        modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate) as NSDate?
        name = try container.decodeIfPresent(String.self, forKey: .name)
        
        if let comments = try container.decodeIfPresent([Comment].self, forKey: .comments) {
            addToComments(NSOrderedSet(array: comments))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let creationDate = creationDate as Date? {
            try container.encode(creationDate, forKey: .creationDate)
        }
        
        if let modificationDate = modificationDate as Date? {
            try container.encode(modificationDate, forKey: .modificationDate)
        }
        
        try container.encode(name, forKey: .name)
        
        if let comments = comments?.array as? [Comment] {
            try container.encode(comments, forKey: .comments)
        }
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    func remove() {
        for commentObj in comments! {
            let comment = commentObj as! Comment
            comment.remove()
        }
        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
    
    static func equal(_ lhs: Item?, _ rhs: Item?) -> Bool {
        return lhs?.name == rhs?.name
    }
}

extension Item {
    override var dates: [Date] {
        var result = [Date]()
        
        if let comments = comments {
            for comment in comments {
                if let comment = comment as? Comment {
                    result += comment.dates
                }
            }
        }
        
        return super.dates + result
    }
}

extension Item: ImportExport {
    var largeImages: [Image] {
        if let comments = self.comments?.array as? [Comment] {
            return comments.map{$0.largeImages}.flatMap{$0}
        }
        else {
            return []
        }
    }
}
