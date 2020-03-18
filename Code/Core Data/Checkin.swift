//
//  Checkin+CoreDataClass.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/12/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(Checkin)
public class Checkin: NSManagedObject, Codable {    
    class func entityName() -> String {
        return "Checkin"
    }
    
    class func newObject() -> Checkin {
        let checkin = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! Checkin
        checkin.date = Date()
        return checkin
    }

    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
       case date
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let context = CoreData.sessionNamed(CoreDataExtras.sessionName).context
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName(), in: context) else { fatalError() }
        self.init(entity: entity, insertInto: context)
        try decode(using: decoder)
    }
    
    func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
    }
}

extension Checkin: Recommendations {
    var dates: [Date] {
        // Forced unwrap is OK because I assign a Date when each object is created.
        return [date!]
    }
}
