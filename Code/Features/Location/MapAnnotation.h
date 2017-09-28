//
//  MapAnnotation.h
//  WhatDidILike
//
//  Created by Christopher Prince on 2/18/13.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapAnnotation : NSObject<MKAnnotation>

- (MapAnnotation *) initWithCoordinate: (CLLocationCoordinate2D) coord;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end
