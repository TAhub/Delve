//
//  Creature.h
//  Delve
//
//  Created by Theodore Abshire on 2/21/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>

//TODO: DESIGN GOAL: this should contain NO info on graphics, besides storing personal colors and stuff
//all graphics should be generated in the controller

@interface Creature : NSObject

-(id)init;

#pragma mark: basic mechanical identity
@property (strong, nonatomic) NSString *race;
@property (strong, nonatomic) NSArray *skillTrees; //an array of NSStrings
@property (strong, nonatomic) NSArray *skillTreeLevels; //an array of integers
@property BOOL good;

//TODO: when making the final skill trees, keep in mind any design notes in these comments

#pragma mark: derived statistics (from race, skill ranks, and equipment)
-(int) damageBonus;
-(int) maxHealth;
-(int) smashResistance; //smash damage is the "anti-warrior" damage type, so mage-type skills and light armors should give this resistance
-(int) cutResistance; //cut damage is the "anti-mage" damage type, so warrior type skills and heavy armors should give this resistance
-(int) shockResistance; //shock damage is the "anti-melee" damage type, so ranged type skills should give this resistance
-(int) burnResistance; //burn damage is the "anti-ranged" damage type, so melee type skills should give this resistance
-(int) maxDodges; //dodges are the "common" defense type, accessable by anyone
-(int) maxBlocks; //blocks are a war-skill-only "super" defense type, and recharge only on their own when you get kills (to reward offense)
-(int) maxHacks; //hacks are used to unlock doors, chests, and to turn off traps if you step in them; it's refilled on map transition
-(int) metabolism; //metabolism is a percentage bonus to how much healing items heal you

#pragma mark: equipment
@property (strong, nonatomic) NSArray *armors; //an array of NSStrings
@property (strong, nonatomic) NSArray *implements; //an array of NSStrings
@property (strong, nonatomic) NSString *weapon;

#pragma mark: status effect flags
@property int forceField;
@property BOOL stunned;

#pragma mark: base variables
@property int health;
@property int dodges;
@property int blocks;
@property int hacks;
@property int x;
@property int y;
@property (strong, nonatomic) NSMutableDictionary *cooldowns;

#pragma mark: organizational flags
@property (strong, nonatomic) NSString *storedAttack;
@property int storedAttackSlot;
@property int storedAttackX;
@property int storedAttackY;

#pragma mark public interface functions
-(void) takeAttack:(NSString *)attackType withPower:(int)power andElement:(NSString *)element;
-(void) useAttackWithTreeNumber:(int)treeNumber andName:(NSString *)name onX:(int)x andY:(int)y;
-(BOOL) startTurn;

@end