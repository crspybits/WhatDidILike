//
//  BaseObject.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/30/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//
//

import Foundation
import CoreData
import SMCoreLib

@objc(BaseObject)
public class BaseObject: NSManagedObject {
    static let modificationDateField = "modificationDate"
    
    // Subclass *must* override
    class func entityName() -> String {
        assert(false)
        return ""
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let context = CoreData.sessionNamed(CoreDataExtras.sessionName).context
        guard let entity = NSEntityDescription.entity(forEntityName: Self.entityName(), in: context) else { fatalError() }
        self.init(entity: entity, insertInto: context)
        try decode(using: decoder)
    }
    
    // Override in subclass
    func decode(using decoder: Decoder) throws {
        // E.g.,
        // let container = decoder.container(keyedBy: CodingKeys.self)
        // self.property = container.decodeIfPresent(String.self, forKey: .property)
    }
    
    class func newObject() -> NSManagedObject {
        let newObj = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! BaseObject
        newObj.creationDate = NSDate()
        newObj.userName = Parameters.userName.stringValue
        return newObj
    }
    
    // See also https://stackoverflow.com/questions/5813309/get-modification-date-for-nsmanagedobject-in-core-data
    override public func willSave() {
        super.willSave()
        
        guard !isDeleted else {
            return
        }
        
        let changes = changedValues()
        
        // Don't repeatedly (recursively) change the modificationDate
        guard changes[Self.modificationDateField] == nil else {
            return
        }
        
        // If only the lastExport field was changed, don't change the modificationDate. Because this is not a user-driven change.
        guard changes[Place.lastExportField] == nil || changes.count > 1 else {
            return
        }
        
        modificationDate = NSDate()
    }
}

extension BaseObject: Recommendations {
    @objc var dates: [Date] {
        return [creationDate as Date?, modificationDate as Date?].compactMap{$0}
    }
}
