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
//TODO: some kind of variable to store position

#pragma mark: organizational flags
//TODO: some kind of variables to store "I am going to hit an area centered at square X with skill Y at the start of my next turn"

@end