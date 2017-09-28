//
//  Map.m
//  Map
//
//  Created by Christopher Prince on 3/22/13.
//  Copyright (c) 2013 Christopher Prince. All rights reserved.
//  This class is a work-around for two issues: (1) the memory leak of MKMapView, and (2) the fact that the default region of MKMapView is not set initally, it takes some time to be set.
//

#import "Map.h"

@implementation Map

static MKMapView *map = nil;
static MKCoordinateRegion defaultRegion;

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        map = [[MKMapView alloc] initWithFrame:frame];
        NSLog(@"created map");
        //NSLog(@"map.centerCoordinate: lat: %f, long: %f", map.centerCoordinate.latitude, map.centerCoordinate.longitude);
        map.delegate = self;
        //defaultRegion = MKCoordinateRegionMake(map.centerCoordinate, MKCoordinateSpanMake(180, 360));
        
        //NSLog(@"defaultRegion: center: lat: %f, long: %f; span: %f dlat: dlong: %f", defaultRegion.center.latitude, defaultRegion.center.longitude, defaultRegion.span.latitudeDelta, defaultRegion.span.longitudeDelta);
        //defaultRegion = MKCoordinateRegionForMapRect(MKMapRectWorld);
    }
    return self;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    static BOOL firstTime = YES;
    if (firstTime)
    {
        defaultRegion = mapView.region;
        firstTime = NO;
        NSLog(@"regionDidChangeAnimated");
        map.delegate = nil;
    }
}

- (MKMapView *) get {
    return map;
}

- (void) reset {
    [map setRegion:defaultRegion animated:NO];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
