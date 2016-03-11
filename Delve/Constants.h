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
#define CREATURE_STUNLENGTH 2
#define CREATURE_SLEEPLENGTH 10
#define CREATURE_POISONPERCENT 5
#define CREATURE_NUM_TREES 5

#pragma mark gameplay constants

#define GAMEPLAY_SCREEN_WIDTH 8
#define GAMEPLAY_SCREEN_HEIGHT 10
#define GAMEPLAY_TILE_SIZE 40
#define GAMEPLAY_MOVE_TIME 0.1f
#define GAMEPLAY_LABEL_TIME 0.5f
#define GAMEPLAY_PANEL_TIME 0.1f
#define GAMEPLAY_LABEL_DISTANCE 50
#define GAMEPLAY_TARGET_RANGE 5
#define GAMEPLAY_SIGHT_LINE_DENSITY 80
#define GAMEPLAY_COUNTDOWN_WARNING_INTERVAL 5

#pragma mark map generator constants

#define GENERATOR_MAX_LINK_LAYERS 100
#define GENERATOR_MAX_CONNECTION_TRIES 200
#define GENERATOR_MAX_BALANCE_TRIES 200
#define GENERATOR_MAX_RANDOM_TREASURE_TRIES 15
#define GENERATOR_CAVE_ROOM_PERCENT 25

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