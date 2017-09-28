//
//  geocodeAddressToLatLong.m
//  WhatDidILike
//
//  Created by Christopher Prince on 2/25/13.
//
//

#import "GeocodeAddressToLatLong.h"
#import <UIKit/UIKit.h>

@interface GeocodeAddressToLatLong()
@property (nonatomic, weak) id<GeocodeAddressToLatLongDelegate> delegate;
@property (nonatomic, weak) UIViewController *vc;
@end

@implementation GeocodeAddressToLatLong

- (void) cleanup {
    mapAddressToCoordinates = nil;
    self.delegate = nil;
}

- (GeocodeAddressToLatLong *) initWithDelegate: (id<GeocodeAddressToLatLongDelegate>) delegate andViewController: (UIViewController *) vc;
{
    self.delegate = delegate;
    self.vc = vc;
    return self;
}

// PRIVATE
- (void) showAlertWithMessage: (NSString *) message;
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self.vc presentViewController:alertController animated:true completion:nil];
}
- (void) failAdressLookup: (id) sender {
    exitMethod();
    addressLookupFailed = YES;
    
    // This will call callback block of code. The only problem with this
    // is that we may not get reasonable error message output.
    [mapAddressToCoordinates cancelGeocode];
    
    [self showAlertWithMessage:@"Error looking up address"];
    [self.delegate failureLookingupAddress];
}

- (void) lookupAddress: (NSString *) address withExitMethod: (GeocodeExitMethod) theExitMethod {
    exitMethod = theExitMethod;
    addressLookupFailed = NO;
    
    // Make sure we've not tried to do two of these mappings
    // simultaneously.
    if (mapAddressToCoordinates) {
        // This now should never happen. But leave it in for completeness
        // because we should never have to pending geocoder requests.
        
        [self showAlertWithMessage:@"Error looking up address"];
        
        [self.delegate failureLookingupAddress];
        exitMethod();
        return;
    }
    
    // Attempt to map the address to GPS coordinates.
    
    // Setup a timer here that will renable the UI if there
    // is some error in mapping the address to coordinates. I have seen
    // cases where at least 30 seconds elapses before an error indication
    // is given. I'm going to assume that address mapping generally takes
    // no more than 10s.
#define GEOCODER_DELAY 10
    [self performSelector:@selector(failAdressLookup:) withObject:nil afterDelay:GEOCODER_DELAY];
    
    mapAddressToCoordinates = [[CLGeocoder alloc] init];
    // Some of code from http://www.techotopia.com/index.php/Integrating_Maps_into_iPhone_iOS_6_Applications_using_MKMapItem#An_Introduction_to_Forward_and_Reverse_Geocoding
    [mapAddressToCoordinates geocodeAddressString: /* @"855 W Dillon Rd, Louisville, Co" */ address
            completionHandler:^(NSArray *placemarks, NSError *error) {
                // indicate that this request is done.
                mapAddressToCoordinates = nil;
                
                if (! addressLookupFailed) {
                    exitMethod();
                }
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(failAdressLookup:) object:nil];
                
                if ((!addressLookupFailed) && (error)) {
                    NSLog(@"Preferences.lookupAddress: Geocode failed with error: %@", error);
                    [self showAlertWithMessage:@"Error looking up address"];
                    
                    [self.delegate failureLookingupAddress];
                    return;
                }
                
                if (addressLookupFailed) return;
                
                if (placemarks && placemarks.count > 0)
                {
                    CLPlacemark *placemark = placemarks[0];
                    CLLocation *location = placemark.location;
                    CLLocationCoordinate2D coords = location.coordinate;
                    
                    NSLog(@"Preferences.lookupAddress: Latitude = %f, Longitude = %f",
                          coords.latitude, coords.longitude);
                    
                    [self.delegate successLookingupAddress: coords.latitude andLongitude: coords.longitude];
                } else {
                    // What happened here??
                    [self showAlertWithMessage:@"Error looking up address"];
                    [self.delegate failureLookingupAddress];
                }
            }
     ];
}

@end
