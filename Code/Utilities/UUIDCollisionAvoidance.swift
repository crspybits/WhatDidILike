//
//  UUIDCollisionAvoidance.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 4/1/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

// Assumes that we can detect a UUID collision local to the device.

enum UUIDCollisionResult<T> {
    // Either of these can be returned in the case of a collision, but for a given implementation this choice must be consistent.
    case exists
    case existsWithObject(_ collidingObject: T)
    
    case doesNotExist
    
    func exists() -> Bool {
        switch self {
        case .exists, .existsWithObject:
            return true
        case .doesNotExist:
            return false
        }
    }
}

protocol UUIDCollisionAvoidance {
    associatedtype T
    
    // Checks if a proposed new uuid exists, on the device, for this context.
    static func alreadyExists(uuid: UUID) throws -> UUIDCollisionResult<T>
}

enum UUIDCollisionAvoidanceError: Error {
    case failedCreatingUUID(String)
}

extension UUIDCollisionAvoidance {
    static func alreadyExists(uuid: String) throws ->  UUIDCollisionResult<T> {
        guard let uuidStruct = UUID(uuidString: uuid) else {
            throw UUIDCollisionAvoidanceError.failedCreatingUUID(uuid)
        }
        
        return try alreadyExists(uuid: uuidStruct)
    }

    // Generate a UUID that we know doesn't collide with any UUID's in this context in the app, on the device.
    static func realUUID() throws -> UUID {
        // The reasoning here is that the likelihood of a collision is low. Thus, iterating if there is a collision will not take long and will terminate.
        repeat {
            let uuid = UUID()
            if try alreadyExists(uuid: uuid).exists() {
                continue
            }
            return uuid
        } while true
    }
    
    // Like realUUID above, but returns a String.
    static func realUUID() throws -> String {
        return try realUUID().uuidString
    }
}
