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
-(BOOL) opaque;
-(BOOL) stairs;
-(BOOL) canUnlock;
-(void) unlock;
-(BOOL) canRubble;
-(void) rubble;
-(BOOL) canAlternate;
-(void) alternate;
-(NSString *) spriteName;
-(UIColor *) color;
@property (weak, nonatomic) Creature *inhabitant;
@property BOOL visible;
@property BOOL lastVisible;
@property BOOL discovered;
@property BOOL changed;
@property (strong, nonatomic) NSMutableSet *aoeTargeters;

@property TargetLevel targetLevel;
@property PathDirection direction;
@property int distance;


-(BOOL) validPlacementSpot;

#pragma mark saving and loading
-(void)saveWithX:(int)x andY:(int)y;
-(id)initWithX:(int)x andY:(int)y;

#pragma mark item info
@property TreasureType treasureType;
@property (strong, nonatomic) Item *treasure;

@end