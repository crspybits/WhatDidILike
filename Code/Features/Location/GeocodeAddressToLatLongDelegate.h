//
//  geocodeAddressToLatLongDelegate.h
//  WhatDidILike
//
//  Created by Christopher Prince on 2/25/13.
//
//

#import <Foundation/Foundation.h>

@protocol GeocodeAddressToLatLongDelegate <NSObject>

// This will be called if a failure occurs converting an address to
// coordinates. An alert view will be given to the user before this is
// called.
- (void) failureLookingupAddress;

// Called when successful; with the latitude and longitude of the successful
// conversion.
- (void) successLookingupAddress: (float) latitude andLongitude:(float) longitude;

@end
