//
//  SecurityScopedURL.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/21/20.
//  Copyright © 2020 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

extension URL {
    enum SecurityScopedURLError: Error {
        case failedToStartAccessingSecurityScopedResource
        case failedToResolveBookmark
        case staleBookmark
    }
    
    // Security-scoped URL's don't survive app relaunches. You have to make bookmarks and save them.
    // Apparently, any sub-folders or files in a security-scoped URL folder are also security-scoped, so need to be accessed in the security-scoped manner.
    // See https://developer.apple.com/documentation/uikit/view_controllers/providing_access_to_directories
    
    func bookmarkForSecurityScopedResource() throws -> Data {
        guard startAccessingSecurityScopedResource() else {
            throw SecurityScopedURLError.failedToStartAccessingSecurityScopedResource
        }
        
        // Make sure you release the security-scoped resource when you are done.
        defer { stopAccessingSecurityScopedResource() }
        
        return try bookmarkData(options: [.minimalBookmark], includingResourceValuesForKeys: nil, relativeTo: nil)
    }
    
    // 'withSecurityScope' is unavailable in iOS: https://stackoverflow.com/questions/52524827/withsecurityscope-not-available-in-nsurl-bookmarkcreationoptions
    static func securityScopedResourceFromBookmark(data: Data) throws -> URL {
        var isStale = false
                
        guard let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) else {
            throw SecurityScopedURLError.failedToResolveBookmark
        }
        
        guard !isStale else {
            throw SecurityScopedURLError.staleBookmark
        }
        
        return url
    }
    
    enum Accessor {
        case securityScoped
        case none
    }
    
    func accessor(_ type: Accessor, callback: (URL) throws -> ()) throws {
        switch type {
        case .none:
            try callback(self)
        case .securityScoped:
            guard startAccessingSecurityScopedResource() else {
                throw SecurityScopedURLError.failedToStartAccessingSecurityScopedResource
            }
            
            try callback(self)
            
            stopAccessingSecurityScopedResource()
        }
    }
}



