//
//  Map.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Creature;
@class Item;

//TODO: DESIGN GOAL: this should contain NO info on graphics

@protocol MapDelegate

-(void)moveCreature:(Creature *)creature withBlock:(void (^)(void))block;
-(void)attackAnimation:(NSString *)name withElement:(NSString *)element fromPerson:(Creature *)creature targetX:(int)x andY:(int)y withEffectBlock:(void (^)(void))block;
-(void)updateTiles;
-(void)updateStats;

@end

@interface Map : NSObject

-(id)init;

@property (strong, nonatomic) NSMutableArray *tiles; //an array of arrays of tiles
@property (strong, nonatomic) NSMutableArray *creatures; //an array of creatures, for turn order
@property (weak, nonatomic) Creature *player;
@property (strong, nonatomic) NSMutableArray *inventory; //an array of items

-(int)width;
-(int)height;
-(BOOL)yourTurn;

-(void)update;
-(void)recalculateVisibility;
-(void)tilesChanged;
-(void)statsChanged;

-(BOOL)moveWithX:(int)x andY:(int)y;
-(BOOL)movePerson:(Creature *)person withX:(int)x andY:(int)y;
-(BOOL)canPickUp;
-(BOOL)canCraft;
-(BOOL)canPayForRecipie:(NSString *)recipie;
-(void)payForRecipie:(NSString *)recipie;
-(Item *)makeItemFromRecipie:(NSString *)recipie;
-(void)addItem:(Item *)item;

@property (weak, nonatomic) id<MapDelegate> delegate;

@end