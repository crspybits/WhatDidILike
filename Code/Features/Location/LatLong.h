//
//  LatLong.h
//  LatLong
//
//  Created by Christopher Prince on 2/11/13.
//  Copyright (c) 2013 Christopher Prince. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "LatLongDelegate.h"

@interface LatLong : CLLocationManager<CLLocationManagerDelegate> {
    NSObject<LatLongDelegate> *theDelegate;
    BOOL calledHaveReasonablyAccurateCoordinates;
    BOOL stopped;
    NSLock *lock;
    BOOL requestCancelled;
}

- (void) cleanup;

// This will be nil if no location could be obtained (e.g.,
// if location services are turned off.
@property (nonatomic, retain) CLLocation *coords;

// These init methods return nil if location services are not available
// (e.g., iPod Touch).

// Will not generate any coords if the user doesn't allow the app
// to use the phone's current location
// callback is called when the attempt has been made to gain
// the coords; this may be unsuccessful.
// Default timeout duration is 15 seconds.
- (LatLong *) initWithDelegate: (NSObject<LatLongDelegate> *) delegate;

- (LatLong *) initWithDelegate: (NSObject<LatLongDelegate> *) delegate andTimeout: (int) timeoutDurationInSeconds;

// Stop the location manager; don't further refine the coordinates;
// no effect if already stopped.
- (void) stop;

// Stop and don't call method on delegate.
- (void) stopWithoutCallback;

@end
