//
//  UIResponder+FirstResponder.h
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/10/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

// From https://stackoverflow.com/questions/1823317/get-the-current-first-responder-without-using-a-private-api

#import <UIKit/UIKit.h>

@interface UIResponder (FirstResponder)
+(id)currentFirstResponder;
@end
