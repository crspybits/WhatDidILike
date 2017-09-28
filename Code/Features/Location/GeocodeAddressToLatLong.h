//
//  GeocodeAddressToLatLong.h
//  WhatDidILike
//
//  Created by Christopher Prince on 2/25/13.
//
//

#import <Foundation/Foundation.h>
#import "GeocodeAddressToLatLongDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

typedef void (^GeocodeExitMethod)(void);

@interface GeocodeAddressToLatLong : NSObject {
    BOOL addressLookupFailed;
    CLGeocoder *mapAddressToCoordinates;
    GeocodeExitMethod exitMethod;
}

- (void) cleanup;

- (GeocodeAddressToLatLong *) initWithDelegate: (id<GeocodeAddressToLatLongDelegate>) delegate andViewController: (UIViewController *) vc;

// Initiate an address lookup; delegate methods will be called.
// When the geocoding stops (or on an error), the exit method is called.
- (void) lookupAddress: (NSString *) address withExitMethod: (GeocodeExitMethod) exitMethod;

@end
