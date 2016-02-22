//
//  Creature.m
//  Delve
//
//  Created by Theodore Abshire on 2/21/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Creature.h"
#import "Map.h"
#import "Tile.h"
#import "Constants.h"

@interface Creature()

@property (weak, nonatomic) Map *map;

@end


@implementation Creature

-(id)initWithX:(int)x andY:(int)y onMap:(Map *)map
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
		
		_x = x;
		_y = y;
		_map = map;
		
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

-(BOOL) validTargetSpotFor:(NSString *)attack atX:(int)x andY:(int)y openSpotsAreFine:(BOOL)openSpots
{
	//set openSpotsAreFine to true if you want to find any place you can theoretically attack, not just places with people to hit
	
	if (!loadValueBool(@"Attacks", attack, @"range"))
	{
		//it's a 0-range attack
		//so it can only target your own square
		return (x == self.x && y == self.y);
	}
	else
	{
		//are you in range?
		int range = loadValueNumber(@"Attacks", attack, @"range").intValue;
		int distance = ABS(x - self.x) + ABS(y - self.y);
		if (distance > range || //maximum range
			(distance == 1 && range > 1)) //minimum range
			return false;
		
		//make sure it's not a solid wall
		Tile *targetTile = self.map.tiles[self.storedAttackY][self.storedAttackX];
		if (targetTile.solid)
			return false;
		
		//TODO: might want to check for line of sight
		//maybe via some kind of line of sight storage map
		//so nobody can target a square you can't see, that should be fine
		
		if (openSpots || loadValueBool(@"Attacks", attack, @"teleport"))
		{
			//it's ok as long as there isn't an ally there
			return (targetTile.inhabitant == nil || targetTile.inhabitant.good == self.good);
		}
		else
		{
			//is there any valid target (IE anybody not on your side) in the aoe?
			__block BOOL anyValid = false;
			BOOL good = self.good;
			[self applyBlock:
			^void (Tile *tile){
				if (tile.inhabitant != nil && tile.inhabitant.good != good)
					anyValid = true;
			} forAttack:attack onX:x andY:y];
			return anyValid;
		}
	}
}

-(void)applyBlock:(void (^)(Tile *))block forAttack:(NSString *)attack onX:(int)x andY:(int)y
{
	int radius = 0;
	if (loadValueBool(@"Attacks", attack, @"radius"))
		radius = (loadValueNumber(@"Attacks", attack, @"radius").intValue - 1) / 2;
	int startX = MAX(x - radius, 0);
	int startY = MAX(y - radius, 0);
	int endX = MIN(x + radius, self.map.width - 1);
	int endY = MIN(y + radius, self.map.height - 1);
	for (int y = startY; y <= endY; y++)
		for (int x = startX; x <= endX; x++)
		{
			Tile *tile = self.map.tiles[y][x];
			block(tile);
		}
}

-(void) useAttackWithTreeNumber:(int)treeNumber andName:(NSString *)name onX:(int)x andY:(int)y
{
	//TODO: you shouldn't be able to use hurt-self attacks if you are under half the health cost
	//or ammo-using attacks if you don't have ammo
	//or attacks if you have the cooldown over 0
	
	//check to see if you can target that spot
	if (![self validTargetSpotFor:name atX:x andY:y openSpotsAreFine:NO])
		return;
	
	self.storedAttack = name;
	self.storedAttackSlot = treeNumber;
	self.storedAttackX = x;
	self.storedAttackY = y;
	
	if (!loadValueBool(@"Attacks", name, @"area"))
		[self unleashAttack]; //release the attack immediately
	
	
	//pay costs
	if (loadValueBool(@"Attacks", self.storedAttack, @"hurt user"))
		self.health = MAX(self.health - loadValueNumber(@"Attacks", self.storedAttack, @"hurt user").intValue, 1);
	//TODO: use ammo
	//TODO: set cooldown
}

-(void) unleashAttack
{
	//TODO: this should probably signal the start of some animation
	//and only run the actual effect code afterwards
	
	
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
	
	
	__weak typeof(self) weakSelf = self;
	[self applyBlock:
	^void (Tile *tile){
		if (tile.inhabitant != nil)
		{
			Creature *hit = tile.inhabitant;
			
			//apply attack
			if ((!loadValueBool(@"Attacks", weakSelf.storedAttack, @"range") || //if it's a self-targeting attack
				 (hit.good != weakSelf.good)) && //or if it's targeting an enemy
				!hit.dead) //don't hit dead people
			{
				[hit takeAttack:weakSelf.storedAttack withPower:power andElement:element];
				if (hit.dead)
				{
					//you killed someone!
					weakSelf.blocks = MIN(weakSelf.blocks + 1, weakSelf.maxBlocks);
					//TODO: any other bennies for getting a kill
				}
			}
			
			//teleport, if that's what the skill asks for
			if (loadValueBool(@"Attacks", weakSelf.storedAttack, @"teleport"))
			{
				if (hit != nil)
				{
					hit.x = weakSelf.x;
					hit.y = weakSelf.y;
				}
				weakSelf.x = weakSelf.storedAttackX;
				weakSelf.y = weakSelf.storedAttackY;
				
				//TODO: this might need to update sprites, etc
			}
		}
	} forAttack:self.storedAttack onX:self.storedAttackX andY:self.storedAttackY];
	
	
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
-(BOOL) dead
{
	return self.health == 0;
}

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