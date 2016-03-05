//
//  Tile.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Constants.h"

@class Creature;
@class Item;

//TODO: DESIGN GOAL: this should contain NO info on graphics

@interface Tile : NSObject

-(id)initWithType:(NSString *)type;

@property (strong, nonatomic) NSString *type;
-(BOOL) solid;
-(BOOL) stairs;
-(BOOL) canUnlock;
-(void) unlock;
-(BOOL) canRubble;
-(void) rubble;
-(NSString *) spriteName;
-(UIColor *) color;
@property (weak, nonatomic) Creature *inhabitant;
@property BOOL visible;
@property BOOL lastVisible;
@property BOOL discovered;
@property BOOL changed;
@property (strong, nonatomic) NSMutableSet *aoeTargeters;
@property TargetLevel targetLevel;
-(BOOL) validPlacementSpot;

#pragma mark item info
@property TreasureType treasureType;
@property (strong, nonatomic) Item *treasure;

@end