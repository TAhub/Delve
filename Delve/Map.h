//
//  Map.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Creature;

//TODO: DESIGN GOAL: this should contain NO info on graphics

@protocol MapDelegate

-(void)moveCreature:(Creature *)creature withBlock:(void (^)(void))block;
-(void)updateTiles;

@end

@interface Map : NSObject

-(id)init;

@property (strong, nonatomic) NSMutableArray *tiles; //an array of arrays of tiles
@property (strong, nonatomic) NSMutableArray *creatures; //an array of creatures, for turn order
@property (weak, nonatomic) Creature *player;

-(int)width;
-(int)height;
-(BOOL)yourTurn;

-(void)update;
-(void)recalculateVisibility;
-(void)tilesChanged;

-(BOOL)moveWithX:(int)x andY:(int)y;

@property (weak, nonatomic) id<MapDelegate> delegate;

@end