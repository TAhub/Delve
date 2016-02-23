//
//  Constants.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <UIKit/UIKit.h>

#pragma mark creature constants
#define CREATURE_RESISTANCEFACTOR 35

#pragma mark gameplay constants

#define GAMEPLAY_SCREEN_WIDTH 8
#define GAMEPLAY_SCREEN_HEIGHT 10
#define GAMEPLAY_TILE_SIZE 40
#define GAMEPLAY_MOVE_TIME 0.6f

#pragma mark enums



#pragma mark plist accessors

UIColor *loadColor(NSString *colorCode);
NSDictionary *loadEntries(NSString *category);
NSDictionary *loadEntry(NSString *category, NSString *entry);
NSArray *loadArrayEntry(NSString *category, NSString *entry);
NSObject *loadValue(NSString *category, NSString *entry, NSString *value);
NSNumber *loadValueNumber(NSString *category, NSString *entry, NSString *value);
NSString *loadValueString(NSString *category, NSString *entry, NSString *value);
UIColor *loadValueColor(NSString *category, NSString *entry, NSString *value);
NSArray *loadValueArray(NSString *category, NSString *entry, NSString *value);
BOOL loadValueBool(NSString *category, NSString *entry, NSString *value);

#pragma mark tests
void passiveBalanceTest();