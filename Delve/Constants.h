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
#define CREATURE_FORCEFIELDDECAY 3

#pragma mark gameplay constants

#define GAMEPLAY_SCREEN_WIDTH 8
#define GAMEPLAY_SCREEN_HEIGHT 10
#define GAMEPLAY_TILE_SIZE 40
#define GAMEPLAY_MOVE_TIME 0.15f
#define GAMEPLAY_TARGET_RANGE 5
#define GAMEPLAY_SIGHT_LINE_DENSITY 80

#pragma mark map generator constants

#define GENERATOR_MAX_LINK_LAYERS 100
#define GENERATOR_MAX_CONNECTION_TRIES 200
#define GENERATOR_MAX_BALANCE_TRIES 200
#define GENERATOR_MAX_RANDOM_TREASURE_TRIES 15

#pragma mark enums

typedef NS_ENUM(NSInteger, ItemType) {
	ItemTypeInventory,
	ItemTypeImplement,
	ItemTypeArmor
};

typedef NS_ENUM(NSInteger, GeneratorRoomExit) {
	GeneratorRoomExitWall,
	GeneratorRoomExitDoor,
	GeneratorRoomExitPathDoor,
	GeneratorRoomExitLockedDoor,
	GeneratorRoomExitNoDoor
};

typedef NS_ENUM(NSInteger, TreasureType) {
	TreasureTypeLocked,
	TreasureTypeChest,
	TreasureTypeBag,
	TreasureTypeFree,
	TreasureTypeNone
};

typedef NS_ENUM(NSInteger, TargetLevel) {
	TargetLevelTarget,
	TargetLevelInRange,
	TargetLevelOutOfRange
};


#pragma mark image modification

UIImage *mergeImages(NSArray *images, CGPoint anchorPoint, NSArray *yAdds);
UIImage *colorImage(UIImage *image, UIColor *color);

#pragma mark plist accessors

UIColor *loadColor(NSString *colorCode);
UIColor *loadColorFromName(NSString *name);
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
void recipieBalanceTest();