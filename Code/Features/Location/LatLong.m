//
//  LatLong.m
//  LatLong
//
//  Created by Christopher Prince on 2/11/13.
//  Copyright (c) 2013 Christopher Prince. All rights reserved.
//

// In seconds; duration of attempt to obtain lat/long coordinates
#define DURATION_OF_ATTEMPT 10.0l

// Reasonably accurate is within 100 meters
#define REASONABLY_ACCURATE 100.0

#import "LatLong.h"

@interface LatLong()
@property (nonatomic) int timeout;
@end

@implementation LatLong
@synthesize coords;

- (void) cleanup {
    theDelegate = nil;
    lock = nil;
}

- (void)stopUpdatingLocationWithCallback: (BOOL) callback {
    [lock lock];
    if (! stopped) {
        [self stopUpdatingLocation];
        self.delegate = nil;
        NSLog(@"LatLong.stopUpdatingLocation: Stopped location manager");
        if (callback) {
            if (theDelegate) {
                [theDelegate finishedAttemptingToObtainCoordinates];
                theDelegate = nil; // so we don't call this method twice
            }
        }
        stopped = YES;
    }
    [lock unlock];
}

// We have a race condition for calling this method. 1) The automatic
// call may occur with the timeout; 2) the stop method may be called.
// Since I don't want finishedAttemptingToObtainCoordinates to be called
// twice, I'm going to place some synchronization in this.
- (void)stopUpdatingLocation: (id) sender {
    [self stopUpdatingLocationWithCallback:YES];
}

- (void) cancelPreviousRequest {
    [lock lock];
    if (! requestCancelled) {
        // we can also cancel our previous performSelector:withObject:afterDelay: - it's no longer necessary
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocation:) object:nil];
        requestCancelled = YES;
    }
    [lock unlock];
}

- (void) stopWithoutCallback {
    [self cancelPreviousRequest];
    [self stopUpdatingLocationWithCallback: NO];
}

- (void) stop {
    [self cancelPreviousRequest];
    [self stopUpdatingLocation:nil];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"LatLong.didFailWithError: %@", error);
}

// Delegate method for less than IOS6
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    NSLog(@"LatLong.didUpdateToLocation: newLocation= %@", [newLocation description]);
    [self didUpdateToLocation:newLocation];
}

// Delegate method for IOS6 and greater
// Delegate method for CLLocationManager; called when hardware gets
// new location; Note that if the user has turned off location services
// for this app, we will not get any callbacks on this when we turn
// on location services.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    // The location at the end of the array is the most recent
    CLLocation *newLocation = [locations objectAtIndex:[locations count]-1];
    NSLog(@"LatLong.didUpdateLocations: newLocation= %@", [newLocation description]);
    [self didUpdateToLocation:newLocation];
}

- (void) didUpdateToLocation: (CLLocation *) newLocation {
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    // Is location stale (older than 5s)
    if (locationAge > 5.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    
    if (newLocation.horizontalAccuracy < 0) return;
    // test the measurement to see if it is more accurate than the previous measurement
    if (coords == nil || coords.horizontalAccuracy > newLocation.horizontalAccuracy) {
        
        // Output will reflect best effort
        NSString *output = [[NSString alloc] initWithFormat:@"location: %@\nhorizontal accuracy: %lf",[newLocation description], newLocation.horizontalAccuracy ];
        NSLog(@"LatLong.didUpdateToLocation: %@", output);
        
        // store the location as the "best effort"
        coords = newLocation;
        
        if (! calledHaveReasonablyAccurateCoordinates) {
            if (coords.horizontalAccuracy <= REASONABLY_ACCURATE) {
                [theDelegate haveReasonablyAccurateCoordinates];
                calledHaveReasonablyAccurateCoordinates = YES;
            }
        }
        
        // test the measurement to see if it meets the desired accuracy
        //
        // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue
        // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
        // acceptable accuracy, or depend on the timeout to stop updating. This sample depends on the timeout.
        //
        if (newLocation.horizontalAccuracy <= self.desiredAccuracy) {
            // we have a measurement that meets our requirements, so we can stop updating the location
            //
            // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
            
            [self stop];
            
            NSLog(@"LatLong.didUpdateToLocation: Have a measurement that meets requirements");
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
{
    switch ([CLLocationManager authorizationStatus]) {
    case kCLAuthorizationStatusAuthorizedWhenInUse:
    case kCLAuthorizationStatusAuthorizedAlways:
        NSLog(@"User authorized location services!");
        [self start];
        break;
    
    case kCLAuthorizationStatusRestricted:
    case kCLAuthorizationStatusDenied:
    case kCLAuthorizationStatusNotDetermined:
        break;
    }
}

- (id) initGeneralWithDelegate: (id) delegate andTimeout: (int) timeout {
    coords = nil;
    theDelegate = delegate;
    calledHaveReasonablyAccurateCoordinates = NO;
    stopped = NO;
    requestCancelled = NO;
    lock = [[NSLock alloc] init];
    
    // This is just a global check; it's not a check to see if
    // location services are turned on just for our app.
    if (! [CLLocationManager locationServicesEnabled]) {
        return nil;
    }
    
    NSLog(@"Location services generally enabled");
    
    self = [super init];
    if (self) {
        self.timeout = timeout;
        
        // desiredAccuracyRepresents accuracy in meters; kCLLocationAccuracyBest is a code
        //  (-1) indicating best accuracy. I'm going to use best
        // accuracy because in some cases places (e.g., restaurants)
        // are packed really near to each other (e.g., adjacent restaurants
        // on a street front).
        self.desiredAccuracy = kCLLocationAccuracyBest;
        //[self setDistanceFilter:kCLDistanceFilterNone];
        self.delegate = self;
        
        switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            [self start];
            break;
        
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            return nil;
        
        case kCLAuthorizationStatusNotDetermined:
            [self requestWhenInUseAuthorization];
        }
    } else {
        NSLog(@"LatLong.initGeneralWithDelegate: nil result of call to super init");
    }
    
    return self;
}

- (void) start;
{
    [self startUpdatingLocation];

    // run the location hardware for at most this amount of time;
    // trying to conserve power.
    NSTimeInterval t = self.timeout;

    [self performSelector:@selector(stopUpdatingLocation:) withObject:nil afterDelay:t];
}

- (LatLong *) initWithDelegate: (NSObject<LatLongDelegate> *) delegate andTimeout: (int) timeoutDurationInSeconds {
    return [self initGeneralWithDelegate: delegate andTimeout: timeoutDurationInSeconds];
}

- (LatLong *) initWithDelegate: (NSObject<LatLongDelegate> *) delegate {
    return [self initGeneralWithDelegate: delegate andTimeout: DURATION_OF_ATTEMPT];
}

@end
