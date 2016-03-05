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
#import "Item.h"

@interface Creature()

@end


@implementation Creature

-(id)initWithX:(int)x andY:(int)y onMap:(Map *)map ofEnemyType:(NSString *)type
{
	if (self = [super init])
	{
		_race = loadValueString(@"EnemyTypes", type, @"race");
		_skillTrees = loadValueArray(@"EnemyTypes", type, @"skills");
		_skillTreeLevels = [NSMutableArray arrayWithObjects:@(1), @(1), @(1), @(1), @(1), nil];
		if (loadValueBool(@"EnemyTypes", type, @"implements"))
		{
			_implements = [NSMutableArray arrayWithArray:loadValueArray(@"EnemyTypes", type, @"implements")];
			while (_implements.count < _skillTrees.count)
				[_implements addObject:@""];
		}
		else
			_implements = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", nil];
		if (loadValueBool(@"EnemyTypes", type, @"armors"))
			_armors = [NSMutableArray arrayWithArray:loadValueArray(@"EnemyTypes", type, @"armors")];
		else
			_armors = [NSMutableArray new];
		_weapon = loadValueString(@"EnemyTypes", type, @"weapon");
		_good = NO;
		
		//TODO: raise skill levels appropriately for your level
		//IE a level 3 enemy should raise 2 of its skills
		
		_x = x;
		_y = y;
		_map = map;
		
		[self initializeMisc];
		
	}
	return self;
}

-(id)initWithX:(int)x andY:(int)y onMap:(Map *)map
{
	if (self = [super init])
	{
		//TODO: temporarily set the race and armor list
		_race = @"human";
		_armors = [NSMutableArray arrayWithObjects:@"peasant clothes", @"skullcap", @"steel-toed boots", nil];
//		_race = @"eoling";
//		_armors = [NSMutableArray arrayWithObjects:@"temple dancer outfit", @"goggles", @"white tail banner", nil];
//		_race = @"highborn";
//		_armors = [NSMutableArray arrayWithObjects:@"chestplate", @"gold tiara", @"", nil];
//		_race = @"raider";
//		_armors = [NSMutableArray arrayWithObjects:@"skullcap", @"blue tail banner", nil];
		
		_skillTrees = [NSArray arrayWithObjects:@"bow", @"charm", @"sacred light", @"heresy", @"godly form", nil];
		_skillTreeLevels = [NSMutableArray arrayWithObjects:@(1), @(1), @(1), @(1), @(1), nil];
		_implements = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", nil];
		_weapon = loadValueString(@"Races", _race, @"race start weapon");
		
		//load starting implements for your skill trees
		NSArray *implements = loadArrayEntry(@"Lists", @"starting implements");
		for (int i = 0; i < _implements.count; i++)
		{
			NSString *skillTree = _skillTrees[i];
			if (loadValueBool(@"SkillTrees", skillTree, @"implement"))
			{
				NSString *implementType = loadValueString(@"SkillTrees", skillTree, @"implement");
				for (NSString *implement in implements)
					if ([loadValueString(@"Implements", implement, @"type") isEqualToString:implementType])
					{
						_implements[i] = implement;
						break;
					}
			}
		}
		
		_good = YES;
		
		_x = x;
		_y = y;
		_map = map;
		_awake = false;
		
		[self initializeMisc];
		
	}
	return self;
}

-(void)initializeMisc
{
	//appearance
	self.gender = loadValueBool(@"Races", self.race, @"has gender") ? arc4random_uniform(2) == 0 : 0;
	if (loadValueBool(@"Races", self.race, @"hair styles"))
		self.hairStyle = arc4random_uniform(loadValueNumber(@"Races", self.race, @"hair styles").intValue);
	self.coloration = arc4random_uniform((u_int32_t)loadValueArray(@"Races", self.race, @"colorations").count);
	
	[self recharge];
	
	//organizational flags
	self.storedAttack = nil;
}

-(void) recharge
{
	//base variables
	self.health = self.maxHealth;
	self.dodges = self.maxDodges;
	self.blocks = self.maxBlocks;
	self.hacks = self.maxHacks;
	
	//initialize cooldown dict
	self.cooldowns = [NSMutableDictionary new];
	
	//status effect flags
	self.forceField = 0;
	self.stunned = 0;
	self.extraAction = 0;
	self.poisoned = 0;
	self.sleeping = 0;
	self.stealthed = 0;
}

#pragma mark: item interface functions

-(NSString *)attackDescription:(NSString *)attack
{
	NSMutableString *desc = [NSMutableString stringWithString:attack];
	
	[desc appendFormat:@"\n%@", loadValueString(@"Attacks", attack, @"description")];
	[desc appendString:@"\n"];
	
	NSMutableArray *properties = [NSMutableArray new];
	if (loadValueBool(@"Attacks", attack, @"power"))
		[properties addObject:[NSString stringWithFormat:@"%i %@ damage", loadValueNumber(@"Attacks", attack, @"power").intValue, loadValueString(@"Attacks", attack, @"element")]];
	if (loadValueBool(@"Attacks", attack, @"min range"))
		[properties addObject:[NSString stringWithFormat:@"%i-%i range", loadValueNumber(@"Attacks", attack, @"min range").intValue, loadValueNumber(@"Attacks", attack, @"range").intValue]];
	else
		[properties addObject:[NSString stringWithFormat:@"%i range", loadValueNumber(@"Attacks", attack, @"range").intValue]];
	if (loadValueBool(@"Attacks", attack, @"area"))
	{
		int area = loadValueNumber(@"Attacks", attack, @"area").intValue;
		if (area == 1)
			[properties addObject:@"delayed"];
		else
			[properties addObject:[NSString stringWithFormat:@"%ix%i area", area, area]];
	}
	if (loadValueBool(@"Attacks", attack, @"power") && loadValueBool(@"Attacks", attack, @"friendly"))
		[properties addObject:@"unavoidable"];
	else if (!loadValueBool(@"Attacks", attack, @"dodgeable"))
		[properties addObject:@"undodgeable"];
	if (loadValueBool(@"Attacks", attack, @"stun"))
		[properties addObject:@"stuns"];
	if (loadValueBool(@"Attacks", attack, @"interrupt aoe"))
		[properties addObject:@"interrupts aoes"];
	if (loadValueBool(@"Attacks", attack, @"hurt user"))
		[properties addObject:[NSString stringWithFormat:@"costs %i health", loadValueNumber(@"Attacks", attack, @"hurt user").intValue]];
	if (loadValueBool(@"Attacks", attack, @"ammo"))
		[properties addObject:[NSString stringWithFormat:@"uses a %@", loadValueString(@"Attacks", attack, @"ammo")]];
	if (loadValueNumber(@"Attacks", attack, @"cooldown").intValue > 1)
		[properties addObject:[NSString stringWithFormat:@"%i cooldown", loadValueNumber(@"Attacks", attack, @"cooldown").intValue]];
	if (loadValueBool(@"Attacks", attack, @"extra actions"))
		[properties addObject:[NSString stringWithFormat:@"%i extra actions", loadValueNumber(@"Attacks", attack, @"extra actions").intValue]];
	
	[desc appendString:[properties componentsJoinedByString:@", "]];
	return desc;
}
-(NSString *)weaponDescription:(NSString *)weapon
{
	NSMutableString *desc = [NSMutableString stringWithFormat:@"%@\n+%i%% power", weapon, loadValueNumber(@"Implements", weapon, @"power").intValue];
	NSString *type = loadValueString(@"Implements", weapon, @"type");
	if ([type isEqualToString:@"weapon"])
	{
		[desc appendString:@" to normal attacks"];
		if (!loadValueBool(@"Implements", weapon, @"element"))
			[desc appendString:@", smash element"];
	}
	else
		for (NSString *tree in loadEntries(@"SkillTrees").allKeys)
			if (loadValueBool(@"SkillTrees", tree, @"implement") && [loadValueString(@"SkillTrees", tree, @"implement") isEqualToString:type])
			{
				[desc appendFormat:@" to %@ attacks", tree];
				break;
			}
	if (loadValueBool(@"Implements", weapon, @"element"))
		[desc appendFormat:@", %@ element", loadValueString(@"Implements", weapon, @"element")];
	[desc appendFormat:@"\n%@", loadValueString(@"Implements", weapon, @"description")];
	return desc;
}
-(NSString *)armorDescription:(NSString *)armor
{
	NSMutableString *desc = [NSMutableString stringWithFormat:@"%@\n", armor];
	NSMutableArray *properties = [NSMutableArray new];
	if (loadValueBool(@"Armors", armor, @"damage bonus"))
		[properties addObject:[NSString stringWithFormat:@"+%i%% damage", loadValueNumber(@"Armors", armor, @"damage bonus").intValue]];
	if (loadValueBool(@"Armors", armor, @"health"))
		[properties addObject:[NSString stringWithFormat:@"+%i health", loadValueNumber(@"Armors", armor, @"health").intValue]];
	if (loadValueBool(@"Armors", armor, @"smash resistance"))
		[properties addObject:[NSString stringWithFormat:@"+%i smash resistance", loadValueNumber(@"Armors", armor, @"smash resistance").intValue]];
	if (loadValueBool(@"Armors", armor, @"cut resistance"))
		[properties addObject:[NSString stringWithFormat:@"+%i cut resistance", loadValueNumber(@"Armors", armor, @"cut resistance").intValue]];
	if (loadValueBool(@"Armors", armor, @"burn resistance"))
		[properties addObject:[NSString stringWithFormat:@"+%i burn resistance", loadValueNumber(@"Armors", armor, @"burn resistance").intValue]];
	if (loadValueBool(@"Armors", armor, @"shock resistance"))
		[properties addObject:[NSString stringWithFormat:@"+%i shock resistance", loadValueNumber(@"Armors", armor, @"shock resistance").intValue]];
	if (loadValueBool(@"Armors", armor, @"dodges"))
		[properties addObject:[NSString stringWithFormat:@"+%i dodge", loadValueNumber(@"Armors", armor, @"dodges").intValue]];
	if (loadValueBool(@"Armors", armor, @"blocks"))
		[properties addObject:[NSString stringWithFormat:@"+%i block", loadValueNumber(@"Armors", armor, @"blocks").intValue]];
	if (loadValueBool(@"Armors", armor, @"hacks"))
		[properties addObject:[NSString stringWithFormat:@"+%i hack", loadValueNumber(@"Armors", armor, @"hacks").intValue]];
	if (loadValueBool(@"Armors", armor, @"metabolism"))
		[properties addObject:[NSString stringWithFormat:@"+%i%% metabolism", loadValueNumber(@"Armors", armor, @"metabolism").intValue]];
	if (loadValueBool(@"Armors", armor, @"delay reduction"))
		[properties addObject:[NSString stringWithFormat:@"-%i all cooldowns", loadValueNumber(@"Armors", armor, @"delay reduction").intValue]];
	if (properties.count > 0)
		[desc appendString:[properties componentsJoinedByString:@", "]];
	[desc appendFormat:@"\n%@", loadValueString(@"Armors", armor, @"description")];
	return desc;
}
-(NSString *)treeDescription:(NSString *)tree atLevel:(int)level
{
	NSString *skillDesc = loadValueString(@"SkillTrees", tree, @"description");
	skillDesc = [skillDesc stringByReplacingOccurrencesOfString:@"!he" withString:self.gender ? @"she" : @"he"];
	skillDesc = [skillDesc stringByReplacingOccurrencesOfString:@"!He" withString:self.gender ? @"She" : @"He"];
	skillDesc = [skillDesc stringByReplacingOccurrencesOfString:@"!man" withString:self.gender ? @"woman" : @"man"];
	skillDesc = [skillDesc stringByReplacingOccurrencesOfString:@"!his" withString:self.gender ? @"her" : @"his"];
	
	NSMutableString *desc = [NSMutableString stringWithFormat:@"%@: %i/4", tree, level];
	[desc appendFormat:@"\n%@", skillDesc];
	if (level == 4)
		[desc appendString:@"\nYou are already at the maximum level for this skill!"];
	else
	{
		NSDictionary *skillDict = loadValueArray(@"SkillTrees", tree, @"skills")[level];
		NSMutableArray *passives = [NSMutableArray new];
		if (skillDict[@"damage bonus"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i%% damage", ((NSNumber *)skillDict[@"damage bonus"]).intValue]];
		if (skillDict[@"health"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i health", ((NSNumber *)skillDict[@"health"]).intValue]];
		if (skillDict[@"smash resistance"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i smash resistance", ((NSNumber *)skillDict[@"smash resistance"]).intValue]];
		if (skillDict[@"cut resistance"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i cut resistance", ((NSNumber *)skillDict[@"cut resistance"]).intValue]];
		if (skillDict[@"burn resistance"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i burn resistance", ((NSNumber *)skillDict[@"burn resistance"]).intValue]];
		if (skillDict[@"shock resistance"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i shock resistance", ((NSNumber *)skillDict[@"shock resistance"]).intValue]];
		if (skillDict[@"dodges"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i dodge", ((NSNumber *)skillDict[@"dodges"]).intValue]];
		if (skillDict[@"blocks"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i block", ((NSNumber *)skillDict[@"blocks"]).intValue]];
		if (skillDict[@"hacks"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i hack", ((NSNumber *)skillDict[@"hacks"]).intValue]];
		if (skillDict[@"metabolism"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i%% metabolism", ((NSNumber *)skillDict[@"metabolism"]).intValue]];
		if (skillDict[@"delay reduction"] != nil)
			[passives addObject:[NSString stringWithFormat:@"-%i all cooldowns", ((NSNumber *)skillDict[@"delay reduction"]).intValue]];
		[desc appendString:@"\nNext level will grant you:\n"];
		[desc appendString:[passives componentsJoinedByString:@", "]];
		
		if (skillDict[@"attack"] != nil)
			[desc appendFormat:@"\n\nLearn the attack %@", [self attackDescription:skillDict[@"attack"]]];
		if (skillDict[@"recipies"] != nil)
			[desc appendString:@"\n\nUnlocks new recipies."];
	}
	return desc;
}

#pragma mark: public interface functions

-(void) equipArmor:(Item *)item
{
	int slot = [self slotForItem:item];
	
	//account for changes in max health
	float healthPercent = self.health * 1.0f / self.maxHealth;
	self.armors[slot] = item.name;
	self.health = MIN(MAX(self.maxHealth * healthPercent, 1), self.maxHealth);
	
	//account for other maximums
	self.dodges = MIN(self.dodges, self.maxDodges);
	self.blocks = MIN(self.blocks, self.maxBlocks);
	//don't apply max hacks, it'll lead to tears
}

-(int) slotForItem:(Item *)item
{
	if (item.type == ItemTypeArmor)
	{
		NSString *armorSlot = loadValueString(@"Armors", item.name, @"slot");
		NSArray *racialArmorSlots = loadValueArray(@"Races", self.race, @"armor slots");
		for (int i = 0; i < racialArmorSlots.count; i++)
			if ([armorSlot isEqualToString:racialArmorSlots[i]])
				return i;
		return -1;
	}
	else
	{
		NSString *implementType = loadValueString(@"Implements", item.name, @"type");
		if ([implementType isEqualToString:@"weapon"])
			return -2;
		for (int i = 0; i < self.skillTrees.count; i++)
		{
			NSString *tree = self.skillTrees[i];
			if (loadValueBool(@"SkillTrees", tree, @"implement") && [loadValueString(@"SkillTrees", tree, @"implement") isEqualToString:implementType])
				return i;
		}
		return -1;
	}
}

-(NSArray *) attacks
{
	NSMutableArray *result = [NSMutableArray new];
	[result addObject:@"attack"];
	[result addObject:@"defend"];
	for (int i = 0; i < self.skillTrees.count; i++)
	{
		NSString *skillTree = self.skillTrees[i];
		int skillTreeLevel = ((NSNumber *)self.skillTreeLevels[i]).intValue;
		NSArray *skillTreeArray = loadValueArray(@"SkillTrees", skillTree, @"skills");
		for (int j = 0; j < skillTreeLevel; j++)
		{
			NSDictionary *skill = skillTreeArray[j];
			NSString *attack = skill[@"attack"];
			if (attack != nil)
				[result addObject:attack];
		}
	}
	return result;
}

-(NSArray *) recipies
{
	NSMutableArray *result = [NSMutableArray new];
	for (int i = 0; i < self.skillTrees.count; i++)
	{
		NSString *skillTree = self.skillTrees[i];
		int skillTreeLevel = ((NSNumber *)self.skillTreeLevels[i]).intValue;
		NSArray *skillTreeArray = loadValueArray(@"SkillTrees", skillTree, @"skills");
		for (int j = 0; j < skillTreeLevel; j++)
		{
			NSString *recipieList = skillTreeArray[j][@"recipies"];
			if (recipieList != nil)
				for (NSString *recipie in loadArrayEntry(@"Lists", recipieList))
					if ([self.map canPayForRecipie:recipie]) //can you pay for it?
					{
						//make a test item of that type
						Item *it = [self.map makeItemFromRecipie:recipie];
						if (it.type == ItemTypeInventory || [self slotForItem:it] != -1) //can you use it?
							[result addObject:recipie]; //if you can use it, add it to the list
					}
		}
	}
	return result;
}

-(TargetLevel) targetLevelAtX:(int)x andY:(int)y withAttack:(NSString *)attack
{
	if ([self validTargetSpotFor:attack atX:x andY:y openSpotsAreFine:true])
		return [self validTargetSpotFor:attack atX:x andY:y openSpotsAreFine:false] ? TargetLevelTarget : TargetLevelInRange;
	return TargetLevelOutOfRange;
}

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
		int minRange = 1;
		if (loadValueBool(@"Attacks", attack, @"min range"))
			minRange = loadValueNumber(@"Attacks", attack, @"min range").intValue;
		int distance = ABS(x - self.x) + ABS(y - self.y);
		if (distance > range || distance < minRange)
			return false;
		
		//make sure it's not a solid wall
		Tile *targetTile = self.map.tiles[y][x];
		if (targetTile.solid)
			return false;
		
		//check for line of sight
		if (!targetTile.visible)
			return false;
		
		if (openSpots || //if you're looking for in-range spots
			(loadValueBool(@"Attacks", attack, @"teleport") && !loadValueBool(@"Attacks", attack, @"power"))) //damaging teleports are used normally
		{
			//it's ok as long as there isn't an ally there
			return (targetTile.inhabitant == nil || targetTile.inhabitant.good != self.good);
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
	if (loadValueBool(@"Attacks", attack, @"area"))
		radius = (loadValueNumber(@"Attacks", attack, @"area").intValue - 1) / 2;
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

-(BOOL) canUseAttack:(NSString *)name
{
	//is the cooldown high?
	NSNumber *cooldown = self.cooldowns[name];
	if (cooldown != nil && cooldown.intValue > 0)
		return false;
	
	//can you (at least kinda) pay the health cost?
	if (loadValueBool(@"Attacks", name, @"hurt user") && self.health <= loadValueNumber(@"Attacks", name, @"hurt user").intValue / 2)
		return false;
		
	
	//check to see if you have ammo
	if (self.good && loadValueBool(@"Attacks", name, @"ammo"))
	{
		NSString *ammoType = loadValueString(@"Attacks", name, @"ammo");
		BOOL hasAmmo = false;
		for (Item *item in self.map.inventory)
		{
			if ([item.name isEqualToString:ammoType])
			{
				hasAmmo = true;
				break;
			}
		}
		if (!hasAmmo)
			return false;
	}
	
	return true;
}

-(void) useAttackWithName:(NSString *)name onX:(int)x andY:(int)y
{
	//find which tree has that attack
	int treeNum = -1;
	for (int i = 0; i < self.skillTrees.count && treeNum == -1; i++)
	{
		NSString *skillTree = self.skillTrees[i];
		int skillTreeLevel = ((NSNumber *)self.skillTreeLevels[i]).intValue;
		NSArray *skillTreeArray = loadValueArray(@"SkillTrees", skillTree, @"skills");
		for (int j = 0; j < skillTreeLevel && treeNum == -1; j++)
		{
			NSDictionary *skill = skillTreeArray[j];
			NSString *attack = skill[@"attack"];
			if (attack != nil && [attack isEqualToString:name])
				treeNum = i;
		}
	}
	
	[self useAttackWithTreeNumber:treeNum == -1 ? 0 : treeNum andName:name onX:x andY:y];
}

-(void) useAttackWithTreeNumber:(int)treeNumber andName:(NSString *)name onX:(int)x andY:(int)y
{
	NSLog(@"Using attack %@ from tree %i", name, treeNumber);
	
	//check to see if you can target that spot
	if (![self validTargetSpotFor:name atX:x andY:y openSpotsAreFine:NO])
		return;
	
	self.storedAttack = name;
	self.storedAttackSlot = treeNumber;
	self.storedAttackX = x;
	self.storedAttackY = y;
	
	if (!loadValueBool(@"Attacks", name, @"area"))
		[self unleashAttack]; //release the attack immediately
	else
	{
		if (!self.good)
		{
			//add targeting warnings
			[self applyBlock:
			^(Tile *tile)
			{
				[tile.aoeTargeters addObject:self];
				tile.changed = true;
			} forAttack:name onX:self.storedAttackX andY:self.storedAttackY];
			[self.map.delegate updateTiles];
		}
		
		[self.map update];
	}
	
	//cancel stealth
	if (self.stealthed > 0)
	{
		self.stealthed = 0;
		[self.map.delegate updateCreature:self];
	}

	
	//pay costs
	if (loadValueBool(@"Attacks", name, @"hurt user"))
		self.health = MAX(self.health - loadValueNumber(@"Attacks", name, @"hurt user").intValue, 1);
	
	//use ammo
	if (self.good && loadValueBool(@"Attacks", name, @"ammo"))
	{
		NSString *ammoType = loadValueString(@"Attacks", name, @"ammo");
		for (Item *item in self.map.inventory)
		{
			if ([item.name isEqualToString:ammoType])
			{
				//unload crafts
				self.map.preloadedCrafts = nil;
				
				item.number -= 1;
				if (item.number == 0)
					[self.map.inventory removeObject:item];
				break;
			}
		}
	}
	
	int cooldown = loadValueNumber(@"Attacks", name, @"cooldown").intValue;
	cooldown = MAX(1, cooldown - self.delayReduction);
	self.cooldowns[name] = @(cooldown);
	
	if (self.good)
		[self.map.delegate updateStats];
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
	if (implement.length > 0 && loadValueBool(@"Implements", implement, @"element"))
		element = loadValueString(@"Implements", implement, @"element");
	
	
	//get the attack effect
	NSString *attackEffect = loadValueString(@"Attacks", self.storedAttack, @"attack effect");
	if (implement.length > 0 && loadValueBool(@"Implements", implement, @"attack effect"))
		attackEffect = loadValueString(@"Implements", implement, @"attack effect");
	
	
	NSMutableArray *labels = [NSMutableArray new];
	NSMutableArray *creatures = [NSMutableArray new];
	
	//use the map's delegate stuff to do an attack anim
	__weak typeof(self) weakSelf = self;
	[self.map.delegate attackAnimation:self.storedAttack withElement:element andAttackEffect:attackEffect fromPerson:self targetX:self.storedAttackX andY:self.storedAttackY withEffectBlock:
	^(void (^finalBlock)(void))
	{
		__block BOOL tilesChanged = false;
		[weakSelf applyBlock:
		^void (Tile *tile)
		{
			if (!weakSelf.good && [tile.aoeTargeters containsObject:weakSelf])
			{
				[tile.aoeTargeters removeObject:weakSelf];
				tile.changed = true;
				tilesChanged = true;
			}
			
			Creature *hit = tile.inhabitant;
			if (hit != nil)
			{
				//apply attack
				if (((!loadValueBool(@"Attacks", weakSelf.storedAttack, @"range") && !loadValueBool(@"Attacks", weakSelf.storedAttack, @"area")) || //if it's a non-AOE self-targeting attack
					 (hit.good != weakSelf.good)) && //or if it's targeting an enemy
					!hit.dead) //don't hit dead people
				{
					NSString *hitResult = [hit takeAttack:weakSelf.storedAttack withPower:power andElement:element];
					[labels addObject:hitResult];
					[creatures addObject:hit];
					if (hit.dead)
					{
						//you killed someone!
						weakSelf.blocks = MIN(weakSelf.blocks + 1, weakSelf.maxBlocks);
						//TODO: any other bennies for getting a kill
						
						//remove the dead person from the map
						tile.inhabitant = nil;
						[weakSelf.map.delegate updateCreature:hit];
					}
				}
				
				if (hit.good)
					[weakSelf.map.delegate updateStats];
			}
			
			//teleport, if that's what the skill asks for
			if (loadValueBool(@"Attacks", weakSelf.storedAttack, @"teleport"))
			{
				if (hit != nil)
				{
					((Tile *)weakSelf.map.tiles[weakSelf.y][weakSelf.x]).inhabitant = hit;
					hit.x = weakSelf.x;
					hit.y = weakSelf.y;
				}
				else
					((Tile *)weakSelf.map.tiles[weakSelf.y][weakSelf.x]).inhabitant = nil;
				((Tile *)weakSelf.map.tiles[weakSelf.storedAttackY][weakSelf.storedAttackX]).inhabitant = weakSelf;
				weakSelf.x = weakSelf.storedAttackX;
				weakSelf.y = weakSelf.storedAttackY;
			}
			
		} forAttack:weakSelf.storedAttack onX:weakSelf.storedAttackX andY:weakSelf.storedAttackY];
		
		if (tilesChanged)
			[weakSelf.map.delegate updateTiles];
		
		weakSelf.storedAttack = nil;
		
		UIColor *color = loadColorFromName([NSString stringWithFormat:@"element %@", element]);
		[self.map.delegate floatLabelsOn:creatures withString:labels andColor:color withBlock:finalBlock];
	}];
}

-(BOOL) moveWithX:(int)x andY:(int)y
{
	Tile *tile = self.map.tiles[self.y+y][self.x+x];
	Tile *oldTile = self.map.tiles[self.y][self.x];
	if (tile.canUnlock && self.good && self.hacks > 0)
	{
		[tile unlock];
		tile.changed = true;
		self.hacks -= 1;
		[self.map.delegate updateStats];
		[self.map.delegate updateTiles];
		return true;
	}
	else if (!tile.solid && tile.inhabitant == nil)
	{
		tile.inhabitant = self;
		oldTile.inhabitant = nil;
		self.x += x;
		self.y += y;
		if (self.good)
			[self.map.delegate updateStats];
		return true;
	}
	return false;
}

-(NSString *) takeAttack:(NSString *)attackType withPower:(int)power andElement:(NSString *)element
{
	if (!self.good && !self.awake)
	{
		//this is for if someone is somehow hit while asleep (for instance, by a stealthy player, or with a big AoE)
		self.awake = true;
		[self wakeUpNearby];
	}
	
	if (self.sleeping > 0)
		self.sleeping = 0;
	
	NSString *label = @"";
	
	if (!loadValueBool(@"Attacks", attackType, @"friendly"))
	{
		//don't apply damage, dodge, block, etc on friendly attacks
		
		if (loadValueBool(@"Attacks", attackType, @"dodgeable") && self.dodges > 0)
		{
			self.dodges -= 1;
			//TODO: dodge sound effect
			return @"DODGE";
		}
		
		if (self.blocks > 0)
		{
			self.blocks -= 1;
			//TODO: block sound effect
			return @"BLOCK";
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
				//TODO: block sound effect
				label = @"BLOCK";
			}
			else
			{
				if (self.forceField > 0)
				{
					finalPower -= self.forceField;
					self.forceField = 0;
				}
				
				label = [NSString stringWithFormat:@"%i", finalPower];
				self.health = MAX(self.health - finalPower, 0);
			}
		}
	}
	
	//apply special effects
	if (loadValueBool(@"Attacks", attackType, @"stun"))
	{
		self.stunned = CREATURE_STUNLENGTH;
		self.storedAttack = nil;
	}
	if (loadValueBool(@"Attacks", attackType, @"sleep"))
	{
		self.sleeping = CREATURE_SLEEPLENGTH;
		self.storedAttack = nil;
	}
	if (loadValueBool(@"Attacks", attackType, @"poison"))
	{
		self.poisoned = loadValueNumber(@"Attacks", attackType, @"poison").intValue;
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
	if (loadValueBool(@"Attacks", attackType, @"extra actions"))
		self.extraAction += loadValueNumber(@"Attacks", attackType, @"extra actions").intValue;
	if (loadValueBool(@"Attacks", attackType, @"stealth"))
	{
		self.stealthed += loadValueNumber(@"Attacks", attackType, @"stealth").intValue;
		[self.map.delegate updateCreature:self];
	}
	
	return label;
}

-(void) wakeUpNearby
{
	//TODO: wake distance should probably be an AI variable
	//so some AIs are "louder" than others
	//3 is pretty high, 2 might be a "normal" value
	int wakeDistance = 3;
	
	for (int y = self.y - wakeDistance; y <= self.y + wakeDistance; y++)
		for (int x = self.x - wakeDistance; x <= self.x + wakeDistance; x++)
			if (x >= 0 && y >= 0 && x < self.map.width && y < self.map.height)
			{
				Tile *tile = self.map.tiles[self.y][self.x];
				if (tile.inhabitant != nil && !tile.inhabitant.good)
					tile.inhabitant.awake = true;
			}
}

-(BOOL) startTurn
{
	//fly starting labels
	__weak typeof(self) weakSelf = self;
	if (self.poisoned > 0)
	{
		self.sleeping = 0;
		self.poisoned -= 1;
		
		int pDamage = MIN(MAX(self.maxHealth * CREATURE_POISONPERCENT / 100, 1), self.health - 1);
		if (pDamage > 0)
		{
			//show the damage number
			self.health -= pDamage;
			[self.map.delegate floatLabelsOn:[NSArray arrayWithObject:self] withString:[NSArray arrayWithObject:[NSString stringWithFormat:@"%i", pDamage]] andColor:loadColorFromName(@"element no element") withBlock:
			^()
			{
				if (![weakSelf startTurnInner])
					[weakSelf.map update];
			}];
			return true;
		}
		else //the poison runs its course instantly
			self.poisoned = 0;
	}
	
	if (self.sleeping > 0)
	{
		[self.map.delegate floatLabelsOn:[NSArray arrayWithObject:self] withString:[NSArray arrayWithObject:@"Z"] andColor:loadColorFromName(@"element no damage") withBlock:
		^()
		{
			if (![weakSelf startTurnInner])
				[weakSelf.map update];
		}];
		return true;
	}
	
	
	
	return [self startTurnInner];
}

-(BOOL) startTurnInner
{
//	NSLog(@"Turn started for %@", self.good ? @"player" : @"enemy");
	Tile *tile = self.map.tiles[self.y][self.x];
	
	//wake up when the player gets onscreen, unless they are stealthed
	if (!self.awake && !self.good && tile.visible &&
		(self.map.player.stealthed == 0 || ABS(self.x - self.map.player.x) + ABS(self.y - self.map.player.y) == 1)) //you can detect stealth at range 1
	{
		self.awake = true;
		[self wakeUpNearby];
	}
	
	//TODO: awake ais who spend too many rounds offscreen (this should probably be an AI variable) should go asleep again
	
	if (self.forceField <= CREATURE_FORCEFIELDDECAY)
		self.forceField = 0;
	else
		self.forceField /= CREATURE_FORCEFIELDDECAY;
	
	//reduce all cooldowns
	for (NSString *attack in self.cooldowns.allKeys)
	{
		NSNumber *cooldown = self.cooldowns[attack];
		self.cooldowns[attack] = @(MAX(cooldown.intValue - 1, 0));
	}
	
	if (self.storedAttack != nil)
		[self unleashAttack];
	
	if (self.stealthed > 0)
	{
		self.stealthed -= 1;
		if (self.stealthed == 0)
			[self.map.delegate updateCreature:self];
	}
	
	if (self.stunned > 0)
	{
		self.stunned -= 1;
		return false;
	}
	
	if (self.sleeping > 0)
	{
		self.sleeping -= 1;
		return false;
	}
	
	if (self.awake)
	{
		//TODO: AI action
		
		//for now, the AI just moves towards the player and attacks when possible
		
		//look for an attack you can use on the player
		NSArray *attacks = [self attacks];
		for (int i = 2; i < attacks.count; i++) //skip defend and attack, this is checking your normal attack
		{
			NSString *attack = attacks[i];
			if ([self canUseAttack:attack] && [self validTargetSpotFor:attack atX:self.map.player.x andY:self.map.player.y openSpotsAreFine:NO])
			{
				//pick that attack
				[self useAttackWithName:attack onX:self.map.player.x andY:self.map.player.y];
				return YES;
			}
		}
		
		//TODO: maybe smarter AIs should be able to detect if they are in the target area of an AoE?
		//and walk outside
		
		//try to attack
		if ([self validTargetSpotFor:@"attack" atX:self.map.player.x andY:self.map.player.y openSpotsAreFine:NO])
		{
			//use attack
			[self useAttackWithTreeNumber:0 andName:@"attack" onX:self.map.player.x andY:self.map.player.y];
			return YES;
		}
		
		//see if you can use any self-targeting attacks
		for (int i = 2; i < attacks.count; i++) //skip defend and attack, this is checking your normal attack
		{
			NSString *attack = attacks[i];
			if ([self canUseAttack:attack] && [self validTargetSpotFor:attack atX:self.x andY:self.y openSpotsAreFine:NO])
			{
				//pick that attack
				[self useAttackWithName:attack onX:self.x andY:self.y];
				return YES;
			}
		}
		
		//otherwise, try to walk towards the player
		//AIs shouldnt pursue the player if the AI isn't visible (IE it's far away or in a non-visible tile) AND the player is stealthed
		if (tile.visible || self.map.player.stealthed == 0)
		{
			int xDif = self.map.player.x - self.x;
			int yDif = self.map.player.y - self.y;
			BOOL xFirst = ABS(xDif) > ABS(yDif);
			if ([self.map movePerson:self withX:(xFirst ? copysign(1, xDif) : 0) andY:(!xFirst ? copysign(1, yDif) : 0)])
				return YES;
			if (xDif != 0 && yDif != 0 && [self.map movePerson:self withX:(!xFirst ? copysign(1, xDif) : 0) andY:(xFirst ? copysign(1, yDif) : 0)])
				return YES;
		}
		
		
		//TODO: maybe smarter AIs can do some actual pathfinding, within a certain radius?
		//IE for if the player teleports away, or is behind a small wall or whatever
		
		
		//otherwise, you are stuck, use defend
		[self useAttackWithTreeNumber:0 andName:@"defend" onX:self.x andY:self.y];
		return YES;
	}
	
	if (self.good)
	{
		//check to see if your defenses can passively regenerate
		__block BOOL enemiesNear = false;
		[self applyBlock:
		^(Tile *tile)
		{
			if (tile.inhabitant != nil && !tile.inhabitant.good && (tile.inhabitant.awake || tile.visible))
				enemiesNear = true;
		} forAttack:@"regen range finder" onX:self.x andY:self.y];
		if (!enemiesNear)
		{
			NSLog(@"Regen dodges!");
			
			//regenerate dodges and blocks
			self.dodges = MIN(self.dodges + 1, self.maxDodges);
			self.blocks = MIN(self.blocks + 1, self.maxBlocks);
			[self.map.delegate updateStats];
		}
	}
	
	return self.good || self.awake;
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
-(int) delayReduction
{
	return [self totalBonus:@"delay reduction"];
}


#pragma mark: helpers

-(int)bonusFromImplement:(NSString *)type withName:(NSString *)name
{
	if (type.length == 0)
		return 0;
	
	//find the implement bonus with name "name" from implement of type "type"
	return loadValueNumber(@"Implements", type, name).intValue;
}

-(int)bonusFromArmor:(NSString *)type withName:(NSString *)name
{
	if (type.length == 0)
		return 0;
	
	//find the armor bonus with name "name" from armor of type "type"
	if (loadValueBool(@"Armors", type, name))
		return loadValueNumber(@"Armors", type, name).intValue;
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
	return bonus;
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