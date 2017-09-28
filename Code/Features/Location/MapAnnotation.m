//
//  mapAnnotation.m
//  WhatDidILike
//
//  Created by Christopher Prince on 2/18/13.
//
//

#import "MapAnnotation.h"

@implementation MapAnnotation
@synthesize coordinate;

- (MapAnnotation *) initWithCoordinate: (CLLocationCoordinate2D) coord {
    coordinate = coord;
    
    return self;
}

@end
