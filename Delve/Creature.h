//
//  Creature.h
//  Delve
//
//  Created by Theodore Abshire on 2/21/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@class Map;
@class Item;

//TODO: DESIGN GOAL: this should contain NO info on graphics, besides storing personal colors and stuff
//all graphics should be generated in the controller

@interface Creature : NSObject

-(int)maxAppearanceNumber;
-(id)initWithRace:(NSString *)race skillTrees:(NSArray *)skillTrees andAppearanceNumber:(int)appearanceNumber;
-(id)initWithX:(int)x andY:(int)y onMap:(Map *)map ofEnemyType:(NSString *)type;

#pragma mark: saving and loading
@property BOOL saveFlag;
-(void)saveWithName:(NSString *)name;
-(id)initFromName:(NSString *)name onMap:(Map *)map;

#pragma mark: basic mechanical identity
@property (strong, nonatomic) NSString *race;
@property (strong, nonatomic) NSArray *skillTrees; //an array of NSStrings
@property (strong, nonatomic) NSMutableArray *skillTreeLevels; //an array of integers
@property BOOL good;

#pragma mark: derived statistics (from race, skill ranks, and equipment)
-(int) damageBonus;
-(int) attackBonus; //attack bonus is like damage bonus but only for the standard "attack" skill
-(int) maxHealth;
-(int) smashResistance; //smash damage is the "anti-warrior" damage type, so mage-type skills and light armors should give this resistance
-(int) cutResistance; //cut damage is the "anti-mage" damage type, so warrior type skills and heavy armors should give this resistance
-(int) shockResistance; //shock damage is the "anti-melee" damage type, so ranged type skills should give this resistance
-(int) burnResistance; //burn damage is the "anti-ranged" damage type, so melee type skills should give this resistance
-(int) maxDodges; //dodges are the "common" defense type, accessable by anyone
-(int) maxBlocks; //blocks are a war-skill-only "super" defense type, and recharge only on their own when you get kills (to reward offense)
-(int) maxHacks; //hacks are used to unlock doors, chests, and to turn off traps if you step in them; it's refilled on map transition
-(int) metabolism; //metabolism is a percentage bonus to how much healing items heal you
-(int) delayReduction; //delay reduction reduces cooldowns of attacks, to a minimum of 1
-(int) counter; //counter-attacks are undodgeable, unblockable, and unreducable

-(BOOL) dead;

#pragma mark: equipment
@property (strong, nonatomic) NSMutableArray *armors; //an array of NSStrings
@property (strong, nonatomic) NSMutableArray *implements; //an array of NSStrings
@property (strong, nonatomic) NSString *weapon;

#pragma mark: status effect flags
@property int forceField;
@property int forceFieldNoDegrade;
@property int stunned;
@property int extraAction;
@property int sleeping;
@property int poisoned;
@property int stealthed;
@property int damageBoosted;
@property int defenseBoosted;
@property int immunityBoosted;
@property int skating;
@property int counterBoosted;
@property int counterBoostedStrength;

#pragma mark: base variables
@property int health;
@property int dodges;
@property int blocks;
@property int hacks;
@property int x;
@property int y;
@property (weak, nonatomic) Map *map;
@property (strong, nonatomic) NSMutableDictionary *cooldowns;

#pragma mark: enemy type stuff
@property (strong, nonatomic) NSString *enemyType;
-(NSString *) ai;
-(NSString *) name;
-(NSString *) typeDescription;

#pragma mark: organizational flags
@property (strong, nonatomic) NSString *storedAttack;
@property int storedAttackSlot;
@property int storedAttackX;
@property int storedAttackY;
@property BOOL awake;

#pragma mark: public interface functions
-(void) useAttackWithTreeNumber:(int)treeNumber andName:(NSString *)name onX:(int)x andY:(int)y;
-(void) useAttackWithName:(NSString *)name onX:(int)x andY:(int)y;
-(BOOL) startTurn;
-(BOOL) moveWithX:(int)x andY:(int)y;
-(NSArray *) attacks;
-(BOOL) canUseAttack:(NSString *)name;
-(TargetLevel) targetLevelAtX:(int)x andY:(int)y withAttack:(NSString *)attack;
-(int) slotForItem:(Item *)item;
-(void) equipArmor:(Item *)item;
-(NSArray *) recipies;
-(void) recharge;
-(void) breakStealth;

#pragma mark: item interface functions
-(NSString *)weaponDescription:(NSString *)weapon;
-(NSString *)armorDescription:(NSString *)armor;
-(NSString *)attackDescription:(NSString *)attack;
-(NSString *)treeDescription:(NSString *)tree atLevel:(int)level;

#pragma mark: appearance
@property BOOL gender;
@property int coloration;
@property int hairStyle;

@end