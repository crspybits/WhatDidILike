//
//  SortFilter+Rating.swift
//  WhatDidILike
//
//  Created by Christopher G Prince on 3/14/18.
//  Copyright © 2018 Spastic Muffin, LLC. All rights reserved.
//

import Foundation

#if false
extension SortFilter {
    // Also sets that rating.
    static func computeRating(forLocation location: Location) {
        var resultRating:Float = 0.0
        var numberCommentRatings:Int = 0
        
        if let rating = rating(location.rating) {
            // If the location itself has a rating, use that exclusively.
            location.sortingRating = rating
        }
        else {
            if let items = location.place?.items, items.count > 0 {
                for itemObj in items {
                    let item = itemObj as! Item
                    
                    if let comments = item.comments, comments.count > 0 {
                        for commentObj in comments {
                            let comment = commentObj as! Comment
                            if let rating = rating(comment.rating) {
                                numberCommentRatings += 1
                                resultRating += rating
                            }
                        }
                    }
                }
            }
            
            if numberCommentRatings > 0 {
                // Have some comment ratings. Average them.
                location.sortingRating = resultRating/Float(numberCommentRatings)
            }
            else {
                // A zero initial value will make the locations with no ratings at all sink to the bottom. This will be ambiguous with locations that actually have a 0 rating, but what's a guy to do?
                location.sortingRating = 0.0
            }
        }
    }
    
    // Take into account me/them in terms of ratings. E.g., if I give a rating that should have more weight than if someone else gives a rating.
    private static func rating(_ rating: Rating?) -> Float? {
        if let rating = rating {
            let ratingValue = rating.rating
            if let meThem = rating.meThem {
                if meThem.boolValue {
                    /*
                    Increase by the factor, but limit result to 1.
                    Approximating: f(r, m) <= 1; f(r, m) > r unless r = 1
                    */
                    if ratingValue == 1.0 {
                        return ratingValue
                    }
                    else {
                        return Float(1.0 - pow(1.1, -30.0 * Double(ratingValue)))
                    }
                }
                else {
                    // Decrease by a factor
                    return ratingValue * 0.7
                }
            }
            else {
                return ratingValue
            }
        }
        else {
            return nil
        }
    }
}
#endif
