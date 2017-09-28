//
//  Map.h
//  Map
//
//  Created by Christopher Prince on 3/22/13.
//  Copyright (c) 2013 Christopher Prince. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface Map : NSObject<MKMapViewDelegate>

- (id)initWithFrame:(CGRect)frame;

// get the map; make sure there is about 1 second duration between calling the initWithFrame method of this class and calling get.
- (MKMapView *) get;

// Resets map to the default region, which was established a short time after calling initWithFrame
- (void) reset;

@end
