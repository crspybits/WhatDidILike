//
//  Rating.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 10/16/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(Rating)
public class Rating: NSManagedObject, Codable {
    class func entityName() -> String {
        return "Rating"
    }
    
    class func newObject() -> Rating {
        let rating = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Rating
        
        // These range from 0 to 1. Starting it off mid-way.
        rating.rating = 0.5
        
        return rating
    }
    
    // MARK: Codable
    
    public required convenience init(from decoder: Decoder) throws {
        let context = CoreData.sessionNamed(CoreDataExtras.sessionName).context
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName(), in: context) else { fatalError() }
        self.init(entity: entity, insertInto: context)
        try decode(using: decoder)
    }
    
    enum CodingKeys: String, CodingKey {
        case rating
        case recommendedBy
        case again
        case meThem
    }
        
    func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rating = try container.decodeIfPresent(Float.self, forKey: .rating) ?? 0
        recommendedBy = try container.decodeIfPresent(String.self, forKey: .recommendedBy)
        
        let again = try container.decodeIfPresent(Bool.self, forKey: .again)
        self.again = NSNumber(booleanLiteral: again ?? false)
        let meThem = try container.decodeIfPresent(Bool.self, forKey: .meThem)
        self.meThem = NSNumber(booleanLiteral: meThem ?? false)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rating, forKey: .rating)
        try container.encode(recommendedBy, forKey: .recommendedBy)
        try container.encode(again?.boolValue, forKey: .again)
        try container.encode(meThem?.boolValue, forKey: .meThem)
    }
    
    func remove() {        
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
}
