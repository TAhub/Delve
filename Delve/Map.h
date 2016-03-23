//
//  Map.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@class UIColor;
@class Creature;
@class Item;

//TODO: DESIGN GOAL: this should contain NO info on graphics

@protocol MapDelegate

-(void)moveCreature:(Creature *)creature fromX:(int)x fromY:(int)y withBlock:(void (^)(void))block;
-(void)attackAnimation:(NSString *)name withElement:(NSString *)element suffix:(NSString *)suffix andAttackEffect:(NSString *)attackEffect fromPerson:(Creature *)creature targetX:(int)x andY:(int)y withEffectBlock:(void (^)(void (^)(void)))block andEndBlock:(void (^)(void))endBlock;
-(void)updateTiles;
-(void)updateStats;
-(void)updateCreature:(Creature *)cr;
-(void)goToNextMap;
-(void)floatLabelsOn:(NSArray *)creatures withString:(NSArray *)strings andColor:(UIColor *)color withBlock:(void (^)(void))block;
-(void)countdownWarningWithBlock:(void (^)(void))block;
-(void)presentRepeatPrompt;
-(void)defeat:(NSString *)message;

@end

@interface Map : NSObject

-(id)initFromSave;
-(id)initWithMap:(Map *)map;
-(id)initWithGen:(Creature *)genPlayer;

-(void)saveInventory;
-(void)saveFirst;

@property (strong, nonatomic) NSMutableArray *tiles; //an array of arrays of tiles
@property (strong, nonatomic) NSMutableArray *creatures; //an array of creatures, for turn order
@property (weak, nonatomic) Creature *player;
@property (strong, nonatomic) NSMutableArray *inventory; //an array of items

-(int)width;
-(int)height;
@property int floorNum;
-(BOOL)yourTurn;
-(BOOL)overtime;

@property int countdown;
@property int overtimeCount;

@property (strong, nonatomic) NSString *defaultColor;

-(void)update;
-(void)recalculateVisibility;

-(BOOL)moveWithX:(int)x andY:(int)y;
-(BOOL)movePerson:(Creature *)person withX:(int)x andY:(int)y;
-(BOOL)canPickUp;
-(BOOL)canCraft;
@property (strong, nonatomic) NSArray *preloadedCrafts;
-(BOOL)canPayForRecipie:(NSString *)recipie;
-(void)payForRecipie:(NSString *)recipie;
-(Item *)makeItemFromRecipie:(NSString *)recipie;
-(void)addItem:(Item *)item;
-(PathDirection)pathFromX:(int)fX andY:(int)fY toX:(int)tX andY:(int)tY withRadius:(int)radius;

@property (weak, nonatomic) id<MapDelegate> delegate;

@end