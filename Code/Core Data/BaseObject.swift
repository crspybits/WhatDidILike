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
    
    // Two other fields are defined in `willSave`. These are ignored because they are derived or computed fields and are not a reason for re-exporting an object.
    static let ignoreInWillSave = [
        Place.suggestionField,
        Location.TRY_AGAIN_KEY,
        Location.DISTANCE_KEY,
        Location.internalRatingField
    ]
    
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
    
    class func newObject() throws -> NSManagedObject {
        let newObj = CoreData.sessionNamed(CoreDataExtras.sessionName).newObject(withEntityName: entityName()) as! BaseObject
        newObj.creationDate = NSDate()
        newObj.userName = Parameters.userName.stringValue
        return newObj
    }
    
    // If lastExport and other fields are set, then the modificationDate field is not updated. This is to accomodate a use case where I import a place (hence changing fields), and set the lastExport field at the same time. In this case, I don't want the place needing export.
    // See also https://stackoverflow.com/questions/5813309/get-modification-date-for-nsmanagedobject-in-core-data
    override public func willSave() {
        super.willSave()
        
        guard !isDeleted else {
            return
        }
        
        var changes = changedValues()
        for key in Self.ignoreInWillSave {
            changes.removeValue(forKey: key)
        }
        
        guard changes.count > 0 else {
            return
        }
        
        // Don't repeatedly (recursively) change the modificationDate
        guard changes[Self.modificationDateField] == nil else {
            return
        }
        
        // See my comment at the start of this method.
        guard changes[Place.lastExportField] == nil else {
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
