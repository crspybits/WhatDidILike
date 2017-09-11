//
//  UIResponder+FirstResponder.m
//  WhatDidILike
//
//  Created by Christopher G Prince on 9/10/17.
//  Copyright © 2017 Spastic Muffin, LLC. All rights reserved.
//

#import "UIResponder+FirstResponder.h"

static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

+(id)currentFirstResponder {
     currentFirstResponder = nil;
     [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
     return currentFirstResponder;
}

-(void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end
