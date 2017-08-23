//
//  ConvertFromV1.m
//  WhatDidILike
//
//  Created by Christopher Prince on 8/22/15.
//  Copyright (c) 2015 Spastic Muffin, LLC. All rights reserved.
//


#import "ConvertFromV1.h"
#import <SMCoreLib/SMCoreLib.h>
#import <CoreLocation/CoreLocation.h>
#import "WhatDidILike-Swift.h"

#define RESTAURANTS         @"Restaurants.dat"

#define KEY_DATE @"date"
#define KEY_USER_NAME @"userName"
// Name of place (NSString)
#define PLACE_KEY_NAME @"restaurantName"
// List or menu of items for the place, an NSArray
#define PLACE_KEY_MENU @"restaurantMenu"
// Boolean represented as NSNumber; true ==> I liked it; false ==> you liked it.
// Don't put "PLACE_" prefix on this key because I use this at other levels
// (i.e., with items and comments) too.
#define KEY_IATE @"iAte"
#define PLACE_KEY_LOCATION @"storeLocation"

// Lat/long in the form of a CLLocation
#define PLACE_KEY_COORDS @"placeCoords"

#define KEY_CATEGORY @"storeCategoryName"

// Date of last modification to place (or item within place
// or comment within item).
#define KEY_MODIFICATION_DATE @"modificationDate"

// NSString general textual description of the place.
#define PLACE_KEY_GENERAL_DESCRIPTION @"placeGeneralDescription"

// An NSArray of list names
#define PLACE_KEY_LISTS @"placeListNames"

// An NSArray of JPEG image names
#define PLACE_KEY_IMAGES @"images"

// Used to keep a record of distances computed while sorting using
// distances.
#define PLACE_KEY_SORT_DIST @"placeSortDist"

// An individual list name (NSString)
#define KEY_LIST_NAME @"listName"

#define ITEM_KEY_NAME @"menuItemName"
#define KEY_RATING @"rating"
#define ITEM_KEY_COMMENTS @"menuItemComments"
#define COMMENT_KEY_IMAGE_FILENAME @"imageFileName"
#define COMMENT_KEY_COMMENT @"menuItemComment"

@implementation ConvertFromV1

+ (void) doIt;
{    
    NSString *placeFilePath = [FileStorage pathToItem:RESTAURANTS];
    // Temporary
    //NSString *placeFilePath = [[NSBundle mainBundle] pathForResource:@"Restaurants" ofType:@"dat"];
    NSArray *places = [FileStorage loadApplicationDataFromFlatFile: placeFilePath];
    
    NSUInteger numberPlaces = 0;
    NSUInteger totalNumberItems = 0;
    NSUInteger totalNumberComments = 0;
    __block NSUInteger numberImages = 0;
    __block NSUInteger numberImageErrors = 0;
    
    // Move a large image in the Documents directory to the LARGE_IMAGE_DIRECTORY. Also renames the image to make the name format more standard. Returns the renamed image file name (without path) or nil on an error.
    NSString * (^moveLargeImage)(NSString *) = ^NSString *(NSString *largeImageFileName) {
        NSString *imageFilePath = [FileStorage pathToItem:largeImageFileName];
        
        // Image file names are currently in the format: WhatDidILike.jpg.XXXXX right now. To make them easier to deal with as images, change them to WhatDidILike.XXXXX.jpg
        NSString *uniqueXXXXPart = [largeImageFileName pathExtension];
        NSString *newFileName = [NSString stringWithFormat:@"%@.%@.jpg", Identifiers. APP_NAME, uniqueXXXXPart];
        
        NSString *imageNewFilePath = [NSString stringWithFormat:@"%@/%@",
                [FileStorage pathToItem:[SMIdentifiers LARGE_IMAGE_DIRECTORY]], newFileName];
        
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] moveItemAtPath:imageFilePath toPath:imageNewFilePath error:&error];
        if (!success || error) {
            numberImageErrors++;
            SPASLogFile(@"Error moving file: %@ to %@", largeImageFileName, [SMIdentifiers LARGE_IMAGE_DIRECTORY]);
            return nil;
        } else {
            numberImages++;
            return newFileName;
        }
    };
    
    for (NSMutableDictionary *restaurant in places) {
        SMExtendedPlace *coreDataPlace = [SMExtendedPlace newObject];
        
        coreDataPlace.creationDate = restaurant[KEY_DATE];
        coreDataPlace.modificationDate = restaurant[KEY_MODIFICATION_DATE];
        coreDataPlace.generalDescription = restaurant[PLACE_KEY_GENERAL_DESCRIPTION];
        coreDataPlace.name = restaurant[PLACE_KEY_NAME];
        coreDataPlace.category = restaurant[KEY_CATEGORY];
        coreDataPlace.userName = restaurant[KEY_USER_NAME];
        
        // These are not "newlyAdded" because "newlyAdded" is a hack for dealing with a first responder issue.
        coreDataPlace.newlyAdded = @(NO);
        
        if ([restaurant[PLACE_KEY_LISTS] count] > 0) {
            coreDataPlace.csvListNames = [NSString convertToCSV:restaurant[PLACE_KEY_LISTS]];
        }
        
        SMExtendedLocation *coreDataLocation = [SMExtendedLocation newObject];
        [coreDataPlace addLocationsObject:coreDataLocation];
        
        coreDataLocation.meThem = restaurant[KEY_IATE];
        coreDataLocation.address = restaurant[PLACE_KEY_LOCATION];
        coreDataLocation.rating = restaurant[KEY_RATING];
        
        // Since the location info was all previously part of the place info, it makes sense to also use the creation date and modification date here.
        coreDataLocation.creationDate = coreDataPlace.creationDate;
        coreDataLocation.modificationDate = coreDataPlace.modificationDate;

        if ([restaurant[PLACE_KEY_IMAGES] count] > 0) {
            NSArray *placeImages = restaurant[PLACE_KEY_IMAGES];
            NSMutableArray *newPlaceImageNames = [NSMutableArray new];
            
            // Move these images to the largeImages folder
            for (NSString *imageFileName in placeImages) {
                NSString *newPlaceImageName = moveLargeImage(imageFileName);
                if (newPlaceImageName) {
                    [newPlaceImageNames addObject:newPlaceImageName];
                }
            }
            
            coreDataLocation.csvImageNames = [NSString convertToCSV:newPlaceImageNames];
        }
        
        if (restaurant[PLACE_KEY_COORDS]) {
            CLLocation *location = restaurant[PLACE_KEY_COORDS];
            
            coreDataLocation.latitude = @(location.coordinate.latitude);
            coreDataLocation.longitude = @(location.coordinate.longitude);
        }
        
        NSUInteger numberItems = 0;
        NSUInteger numberComments = 0;

        if ([restaurant[PLACE_KEY_MENU] count] > 0) {

            for (NSDictionary *menuItem in restaurant[PLACE_KEY_MENU]) {
                SMExtendedItem *coreDataItem = [SMExtendedItem newObject];
                [coreDataPlace addItemsObject:coreDataItem];
                
                coreDataItem.userName = menuItem[KEY_USER_NAME];
                coreDataItem.name = menuItem[ITEM_KEY_NAME];
                coreDataItem.creationDate = menuItem[KEY_DATE];
                
                // In the new data format we're not putting a me/them attribute at the item level. If there is a me/them given for the menuItem, we're going to keep it only if there are no comments for the item. To do so, we'll create a dummy comment and set its me/them item. We can also put in some comment text to say that this is just a dummy comment and the rating doesn't have meaning.
                
                // Esimate the last modification date of the item from the latest date in the comments.
                NSDate *lastModDateEstimate = nil;
                
                if ([menuItem[ITEM_KEY_COMMENTS] count] > 0) {
                    for (NSDictionary *commentItem in menuItem[ITEM_KEY_COMMENTS]) {
                        SMExtendedComment *coreDataComment = [SMExtendedComment newObject];
                        [coreDataItem addCommentsObject:coreDataComment];
                        
                        coreDataComment.userName = commentItem[KEY_USER_NAME];
                        coreDataComment.creationDate = commentItem[KEY_DATE];
                        
                        // This isn't really the last modification date, but we don't have one. If we just leave this as nil, then due to the way WDILCoreData is set up, the modification date will be the date the data conversion took place, which is just odd.
                        coreDataComment.modificationDate = coreDataComment.creationDate;
                        
                        coreDataComment.meThem = commentItem[KEY_IATE];
                        coreDataComment.rating = commentItem[KEY_RATING];
                        coreDataComment.comment = commentItem[COMMENT_KEY_COMMENT];
                        
                        NSString *commentImageName = commentItem[COMMENT_KEY_IMAGE_FILENAME];
                        
                        // This image, if any, needs to be moved to the largeImages folder
                        if (commentImageName) {
                            NSString *newImageName = moveLargeImage(commentImageName);
                            if (newImageName) {
                                coreDataComment.csvImageNames = newImageName;
                            }
                        }
                        
                        if (nil == lastModDateEstimate) {
                            lastModDateEstimate = coreDataComment.creationDate;
                        }
                        else {
                            if ([lastModDateEstimate compare:coreDataComment.creationDate] == NSOrderedAscending)
                            {
                                lastModDateEstimate = coreDataComment.creationDate;
                            }
                        }
                        
                        numberComments++;
                    }
                }
                else {
                    // No comments.
                    if (menuItem[KEY_IATE]) {
                        // Add the dummy comment for the me/them.
                        SMExtendedComment *coreDataComment = [SMExtendedComment newObject];
                        [coreDataItem addCommentsObject:coreDataComment];
                        
                        coreDataComment.meThem = menuItem[KEY_IATE];
                        coreDataComment.comment = @"(Dummy comment: Added during data conversion; only the me/them has meaning, and not the rating)";
                    }
                }

                coreDataItem.modificationDate = lastModDateEstimate;
                
                numberItems++;
            } // End item
        } // End menu items
        
        totalNumberItems += numberItems;
        totalNumberComments += numberComments;
        
        SPASLogDetail("Converted place with: %lu items and %lu comments",
                      (unsigned long)numberItems, (unsigned long) numberComments);
        
        [[WDILCoreData session] saveContext];
        numberPlaces++;
    }
    
    NSString *message = nil;
    NSString *title = [NSString stringWithFormat:@"Converted %lu places, with %lu items, %lu comments, and %lu images to new data format.", (unsigned long)numberPlaces, (unsigned long)totalNumberItems, (unsigned long)totalNumberComments, (unsigned long)numberImages];
    
    if (numberImageErrors > 0) {
        message = [NSString stringWithFormat:@"There were %lu errors moving image files.", (unsigned long)numberImageErrors];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:[SMUIMessages session].OkMsg otherButtonTitles: nil];
    [[UserMessage session] showAlert:alert ofType:UserMessageTypeError];
    
    SPASLogDetail("numberPlaces converted: %lu", (unsigned long)numberPlaces);
    SPASLogDetail("total comments converted: %lu", (unsigned long)totalNumberItems);
    SPASLogDetail("total items converted: %lu", (unsigned long)totalNumberComments);
    
    [WDILDefs CONVERTED_FROM_V1].boolValue = YES;
}

@end

