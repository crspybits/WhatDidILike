//
//  Location.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 8/21/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

import Foundation
import CoreData
import SMCoreLib

@objc(Location)
public class Location: BaseObject, ImagesManagedObject, Codable, EquatableObjects {
    static let NAME_KEY = "place.name"
    static let DISTANCE_KEY = "internalDistance"
    static let SUGGESTION_KEY = "place.suggestion"
    static let TRY_AGAIN_KEY = "internalGoBack"

    // I'm not using `internalDistance` directly just to emphasize that this is a little different. It's for the UI so we can order locations by distance.
    // Unit is meters.
    var sortingDistance:Float {
        set {
            internalDistance = newValue
        }
        
        get {
            return internalDistance
        }
    }
    
    func setSortingDistance(from: CLLocation) {
        if let clLocation = location {
            sortingDistance = Float(clLocation.distance(from: from))
        }
        else {
            sortingDistance = Float.greatestFiniteMagnitude
        }
    }
    
    // I'm not using `internalRating` directly just to emphasize that this is a little different. It's for the UI so we can order locations by a measure of rating.
    var sortingRating:Float {
        set {
            internalRating = newValue
        }
        
        get {
            return internalRating
        }
    }
    
    // Doesn't save the core data object when you set.
    // Don't access internalLocation directly. Use this method instead.
    var location:CLLocation? {
        set {
            if newValue == nil {
                internalLocation = nil
            }
            else {
                internalLocation = NSKeyedArchiver.archivedData(withRootObject: newValue!) as Data
            }
        }
        get {
            if internalLocation == nil {
                return nil
            }
            else {
                return (NSKeyedUnarchiver.unarchiveObject(with: internalLocation! as Data) as! CLLocation)
            }
        }
    }
    
    override class func entityName() -> String {
        return "Location"
    }
    
    override class func newObject() throws -> Location {
        let newLocation = try super.newObject() as! Location
        newLocation.rating = Rating.newObject()
        return newLocation
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case creationDate
        case modificationDate
        case address
        
        // Don't need to encode/decode internalDistance as this is computed as a function of the Location's lat/long
        // Similarly, internalGoBack is computed indirectly so don't need to encode/decode.
        
        case location
        
        // Similarly, internalRating is computed indirectly so don't need to encode/decode.
        
        case specificDescription
        case images
        case rating
        case checkin
    }
    
    // Not using `internalLocation` for coding/decoding so I can get JSON in the coding (and not just Data).
        
    override func decode(using decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate) as NSDate?
        modificationDate = try container.decodeIfPresent(Date.self, forKey: .modificationDate) as NSDate?
        address = try container.decodeIfPresent(String.self, forKey: .address)
        
        if let locationDecoder = try container.decodeIfPresent(LocationDecoder.self, forKey: .location) {
            location = locationDecoder.location
        }
        
        specificDescription = try container.decodeIfPresent(String.self, forKey: .specificDescription)

        if let images = try container.decodeIfPresent([Image].self, forKey: .images) {
            addToImages(NSOrderedSet(array: images))
        }
        
        rating = try container.decodeIfPresent(Rating.self, forKey: .rating)
        
        if let checkin = try container.decodeIfPresent(Set<Checkin>.self, forKey: .checkin) {
            addToCheckin(checkin as NSSet)
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
        
        try container.encode(address, forKey: .address)
        try container.encode(location, forKey: .location)
        try container.encode(specificDescription, forKey: .specificDescription)

        if let images = images?.array as? [Image] {
            try container.encode(images, forKey: .images)
        }
        
        try container.encode(rating, forKey: .rating)
        
        if let checkin = checkin as? Set<Checkin> {
            try container.encode(checkin, forKey: .checkin)
        }
    }
    
    struct SortFilterParams {
        let sortingOrder: Parameters.SortOrder
        let isAscending: Bool
        let tryAgainFilter: Parameters.TryAgainFilter
        let distanceFilter: Parameters.DistanceFilter
        let distanceInMiles: Int
    }
    
    class func fetchRequestForAllObjects(sortFilter: SortFilterParams) -> NSFetchRequest<NSFetchRequestResult>? {
        var fetchRequest: NSFetchRequest<NSFetchRequestResult>?
        fetchRequest = CoreData.sessionNamed(CoreDataExtras.sessionName).fetchRequest(
            withEntityName: self.entityName(), modifyingFetchRequestWith: { request in
            
            var subpredicates = [NSPredicate]()
            
            if sortFilter.distanceFilter == .use {
                let amount = NSNumber(value: milesToMeters(miles: Float(sortFilter.distanceInMiles)))
                subpredicates += [NSPredicate(format: "(%K <= %@)", DISTANCE_KEY, amount)]
            }
            
            switch sortFilter.tryAgainFilter {
            case .again:
                subpredicates += [NSPredicate(format: "(%K == %@)", TRY_AGAIN_KEY, NSNumber(booleanLiteral: true))]
                
            case .notAgain:
                subpredicates += [NSPredicate(format: "(%K == %@)", TRY_AGAIN_KEY,
                    NSNumber(booleanLiteral: false))]

            case .dontUse:
                break
            }
            
            if subpredicates.count > 0 {
                let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
                request.predicate = compoundPredicate
            }
        })
        
        var key: String
        
        switch sortFilter.sortingOrder {
        case .distance:
            key = DISTANCE_KEY
            
        case .name:
            key = NAME_KEY
            
        case .suggest:
            key = SUGGESTION_KEY
        }
        
        if fetchRequest != nil {
            let sortDescriptor = NSSortDescriptor(key: key, ascending: sortFilter.isAscending)
            fetchRequest!.sortDescriptors = [sortDescriptor]
        }
        
        return fetchRequest
    }
    
    class func fetchAllObjects() -> [Location]? {
        let locations = try? CoreData.sessionNamed(CoreDataExtras.sessionName)
            .fetchAllObjects(withEntityName: entityName())
        return locations as? [Location]
    }
    
    func save() {
        CoreData.sessionNamed(CoreDataExtras.sessionName).saveContext()
    }
    
    // After the call, uuidOfPlaceRemoved will be set to the uuid of the place iff the associated place was removed as part of this removal.
    func remove(uuidOfPlaceRemoved: inout String?) {
        // Does the place associated with this location have more than one location?
        if place!.locations!.count == 1 {
            // No: the associated place needs to be removed too.
            uuidOfPlaceRemoved = place!.uuid
            place!.remove()
        }
        else {
            uuidOfPlaceRemoved = nil
        }
        
        for imageObj in images! {
            let image = imageObj as! Image
            image.remove()
        }
        
        rating!.remove()
        CoreData.sessionNamed(CoreDataExtras.sessionName).remove(self)
    }
    
    static func metersToMiles(meters:Float) -> Float {
        return (meters/1000.0)*0.621371
    }

    static func milesToMeters(miles:Float) -> Float {
        return miles/(0.000621371)
    }
    
    static func equal(_ lhs: Location?, _ rhs: Location?) -> Bool {
        // For some reason, checking the internalLocations for equality fails, but checking the encoded data succeeds.
        let encoder = JSONEncoder()
        let lhsLocationData = try? encoder.encode(lhs?.location)
        let rhsLocationData = try? encoder.encode(rhs?.location)

        return lhs?.address == rhs?.address &&
            lhsLocationData == rhsLocationData &&
            lhs?.specificDescription == rhs?.specificDescription &&
            Image.equal(lhs?.images?.array as? [Image], rhs?.images?.array as? [Image]) &&
            Rating.equal(lhs?.rating, rhs?.rating) &&
            Checkin.equal(lhs?.checkin as? Set<Checkin>, rhs?.checkin as? Set<Checkin>)
    }
}

extension Location {
    override var dates: [Date] {
        var result = [Date]()
        
        if let images = images {
            for image in images {
                if let image = image as? Image {
                    result += image.dates
                }
            }
        }
        
        if let checkIns = checkin as? Set<Checkin> {
            for checkIn in checkIns {
                result += checkIn.dates
            }
        }
        
        if let rating = rating {
            result += rating.dates
        }
        
        return super.dates + result
    }
}

extension Location: ImportExport {
    var largeImageFiles: [String] {
        if let images = self.images?.array as? [Image] {
            return images.map{$0.largeImageFiles}.flatMap{$0}
        }
        else {
            return []
        }
    }
}
