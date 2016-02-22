//
//  Creature.m
//  Delve
//
//  Created by Theodore Abshire on 2/21/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Creature.h"

@interface Creature()



@end


@implementation Creature

-(id)init
{
	if (self = [super init])
	{
		//TODO: these are all just temporary variables
		_race = @"human";
		_skillTrees = [NSArray arrayWithObjects:@"shield", @"dodge", @"axe", @"spear", @"conditioning", nil];
		_skillTreeLevels = [NSArray arrayWithObjects:@(1), @(1), @(1), @(1), @(1), nil];
		_implements = [NSArray arrayWithObjects:@"rusty shield", @"", @"rusty axe", @"wooden spear", @"", nil];
		_weapon = @"rusty sword";
		_armors = [NSArray arrayWithObjects:@"rusty chestplate", @"rusty helmet", nil];
		_good = YES;
		
		//TODO: position
		
		[self initializeMisc];
		
	}
	return self;
}

-(void)initializeMisc
{
	//base variables
	self.health = self.maxHealth;
	self.dodges = self.maxDodges;
	self.blocks = self.maxBlocks;
	
	//status effect flags
	self.forceField = 0;
	self.stunned = NO;
	
	//organizational flags
	//TODO: add them
}


#pragma mark: derived statistics
-(int) damageBonus
{
	return [self totalBonus:@"damage bonus"];
}
-(int) maxHealth
{
	return [self totalBonus:@"health"];
}
-(int) smashResistance
{
	return [self totalBonus:@"smash resistance"];
}
-(int) cutResistance
{
	return [self totalBonus:@"cut resistance"];
}
-(int) shockResistance
{
	return [self totalBonus:@"shock resistance"];
}
-(int) burnResistance
{
	return [self totalBonus:@"burn resistance"];
}
-(int) maxDodges
{
	return [self totalBonus:@"dodges"];
}
-(int) maxBlocks
{
	return [self totalBonus:@"blocks"];
}


#pragma mark: helpers

-(int)bonusFromImplement:(NSString *)type withName:(NSString *)name
{
	if (type.length == 0)
		return 0;
	
	
	//TODO: find the implement bonus with name "name" from implement of type "type"
	return 0;
}

-(int)bonusFromArmor:(NSString *)type withName:(NSString *)name
{
	if (type.length == 0)
		return 0;
	
	//TODO: find the armor bonus with name "name" from armor of type "type"
	return 0;
}

-(int)bonusFromSkillTree:(NSString *)tree ofRank:(int)rank withName:(NSString *)name
{
	//TODO: find the skill pasive bonus with name "name" from the skill number "rank" from the tree "tree"
	//TODO: keep in mind that the starting rank is 1, not 0; so it doesn't map directly to array index
	return 0;
}

-(int)totalBonus:(NSString *)name
{
	//TODO: get the base bonus from your race
	int bonus = 0;
	
	//get the skill passive bonuses
	for (int i = 0; i < self.skillTrees.count; i++)
	{
		NSString *skillTreeName = self.skillTrees[i];
		int ranks = ((NSNumber *)self.skillTreeLevels[i]).intValue;
		for (int j = 1; j <= ranks; j++)
			bonus += [self bonusFromSkillTree:skillTreeName ofRank:j withName:name];
	}
	
	//get the armor bonuses
	for (int i = 0; i < self.armors.count; i++)
	{
		NSString *armorName = self.armors[i];
		bonus += [self bonusFromArmor:armorName withName:name];
	}
	
	return bonus;
}

@end