//
//  Creature.m
//  Delve
//
//  Created by Theodore Abshire on 2/21/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Creature.h"
#import "Constants.h"

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
	self.hacks = self.maxHacks;
	
	//TODO: initialize cooldowns
	self.cooldowns = [NSMutableDictionary new];
	//each key-value pair should be "attackName string" : "cooldown NSNumber"
	
	//status effect flags
	self.forceField = 0;
	self.stunned = NO;
	
	//organizational flags
	self.storedAttack = nil;
}

#pragma mark: public interface functions

-(void) useAttackWithTreeNumber:(int)treeNumber andName:(NSString *)name onX:(int)x andY:(int)y
{
	//TODO: a range-0 attack always targets your square
	//but that should be done in the targeting phase, not here
	
	//TODO: also, you shouldn't be able to use hurt-self attacks if you are under half the health cost
	//or ammo-using attacks if you don't have ammo
	//or attacks if you have the cooldown over 0
	
	self.storedAttack = name;
	self.storedAttackSlot = treeNumber;
	self.storedAttackX = x;
	self.storedAttackY = y;
	
	if (!loadValueBool(@"Attacks", name, @"area"))
		[self unleashAttack]; //release the attack immediately
	
	//TODO: set cooldown
}

-(void) unleashAttack
{
	//get the implement
	NSString *implement = @"";
	if ([self.storedAttack isEqualToString:@"attack"]) //the implement should be your weapon
		implement = self.weapon;
	else
		implement = self.implements[self.storedAttackSlot];
	
	//get the power
	int power = self.damageBonus + [self bonusFromImplement:implement withName:@"power"];
	
	//get the element
	NSString *element = @"no element";
	if (loadValueBool(@"Attacks", self.storedAttack, @"element"))
		element = loadValueString(@"Attacks", self.storedAttack, @"element");
	//TODO: element override from implement (ie flaming sword does burn, whatever)
	
	//TODO: get the real person/people you hit, based on the AoE
	Creature *hit = self;
	
	[hit takeAttack:self.storedAttack withPower:power andElement:element];
	
	
	//pay costs
	if (loadValueBool(@"Attacks", self.storedAttack, @"hurt user"))
		self.health = MAX(self.health - loadValueNumber(@"Attacks", self.storedAttack, @"hurt user").intValue, 1);
	//TODO: use ammo
	
	
	self.storedAttack = nil;
}

-(void) takeAttack:(NSString *)attackType withPower:(int)power andElement:(NSString *)element
{
	if (!loadValueBool(@"Attacks", attackType, @"friendly"))
	{
		//don't apply damage, dodge, block, etc on friendly attacks
		
		if (loadValueBool(@"Attacks", attackType, @"dodgeable") && self.dodges > 0)
		{
			self.dodges -= 1;
			NSLog(@"Dodged!");
			return;
		}
		
		if (self.blocks > 0)
		{
			self.blocks -= 1;
			NSLog(@"Blocked!");
			return;
		}
		
		if (loadValueBool(@"Attacks", attackType, @"power"))
		{
			//apply damage
			int finalPower = loadValueNumber(@"Attacks", attackType, @"power").intValue;
			
			int resistance = 0;
			if ([element isEqualToString:@"cut"])
				resistance = self.cutResistance;
			else if ([element isEqualToString:@"smash"])
				resistance = self.smashResistance;
			else if ([element isEqualToString:@"burn"])
				resistance = self.burnResistance;
			else if ([element isEqualToString:@"shock"])
				resistance = self.shockResistance;
			
			finalPower = (power * finalPower) / (100 + resistance * CREATURE_RESISTANCEFACTOR);
			
			if (self.forceField >= finalPower)
			{
				self.forceField -= finalPower;
				NSLog(@"Totally blocked by force field!");
			}
			else
			{
				if (self.forceField > 0)
				{
					NSLog(@"Partially blocked by force field!");
					finalPower -= self.forceField;
					self.forceField = 0;
				}
				
				NSLog(@"Took %i damage!", finalPower);
				self.health = MAX(self.health - finalPower, 0);
			}
		}
	}
	
	//apply special effects
	if (loadValueBool(@"Attacks", attackType, @"stun"))
	{
		self.stunned = true;
		self.storedAttack = nil;
	}
	if (loadValueBool(@"Attacks", attackType, @"interrupt aoe"))
		self.storedAttack = nil;
	if (loadValueBool(@"Attacks", attackType, @"dodge restore"))
		self.dodges = MIN(self.dodges + loadValueNumber(@"Attacks", attackType, @"dodge restore").intValue, self.maxDodges);
	if (loadValueBool(@"Attacks", attackType, @"forcefield"))
	{
		int forceFieldPower = loadValueNumber(@"Attacks", attackType, @"forcefield").intValue;
		forceFieldPower = (forceFieldPower * power) / 100;
		self.forceField += forceFieldPower;
	}
}

-(BOOL) startTurn
{
	self.forceField = 0;
	
	//reduce all cooldowns
	for (NSString *attack in self.cooldowns.allKeys)
	{
		NSNumber *cooldown = self.cooldowns[attack];
		self.cooldowns[attack] = @(MAX(cooldown.intValue - 1, 0));
	}
	
	if (self.storedAttack != nil)
		[self unleashAttack];
	
	if (self.stunned)
	{
		self.stunned = false;
		
		return false;
	}
	
	return true;
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
-(int) maxHacks
{
	return [self totalBonus:@"hacks"];
}
-(int) metabolism
{
	return [self totalBonus:@"metabolism"];
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
	//find the skill pasive bonus with name "name" from the skill number "rank" from the tree "tree"
	
	NSArray *skillInfoArray = loadValueArray(@"SkillTrees", tree, @"skills");
	int bonus = 0;
	for (int i = 0; i < rank; i++)
	{
		NSDictionary *skill = skillInfoArray[i];
		if (skill[name] != nil)
			bonus += ((NSNumber *)skill[name]).intValue;
	}
	return 0;
}

-(int)totalBonus:(NSString *)name
{
	//get the base bonus from your race
	int bonus = 0;
	if (loadValueBool(@"Races", self.race, name))
		bonus += loadValueNumber(@"Races", self.race, name).intValue;
	
	//get the skill passive bonuses
	for (int i = 0; i < self.skillTrees.count; i++)
	{
		NSString *skillTreeName = self.skillTrees[i];
		int ranks = ((NSNumber *)self.skillTreeLevels[i]).intValue;
		bonus += [self bonusFromSkillTree:skillTreeName ofRank:ranks withName:name];
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