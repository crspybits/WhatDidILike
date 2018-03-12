//
//  LatLongDelegate.h
//  WhatDidILike
//
//  Created by Christopher Prince on 2/11/13.
//
//

#import <Foundation/Foundation.h>

@protocol LatLongDelegate <NSObject>

- (void)userDidNotAuthorizeLocationServices;

// This will be called after gaining a reasonably accurate pair of
// lat/long coords
- (void)haveReasonablyAccurateCoordinates;

// This will be called after a certain time interval; check the coords
// property of the LatLong object to see if there was success in getting
// coordinates. If the coords property was not nil, then we have
// some coordinates.
- (void) finishedAttemptingToObtainCoordinates;

@end
