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

@property (strong, nonatomic) NSMutableDictionary *cached;

//@property (strong, nonatomic) NSString *attackCacheName;
//@property (strong, nonatomic) NSMutableDictionary *attackCache;

@end


@implementation Creature

#pragma mark: saving and loading

-(void)saveWithName:(NSString *)name
{
	NSMutableArray *saveArray = [NSMutableArray new];
	
	//save identity
	[saveArray addObject:@(self.good ? 1 : 0)];
	[saveArray addObject:self.race];
	if (!self.good)
		[saveArray addObject:self.enemyType];
	for (int i = 0; i < CREATURE_NUM_TREES; i++)
	{
		[saveArray addObject:self.skillTrees[i]];
		[saveArray addObject:self.skillTreeLevels[i]];
	}
	
	//save equipment
	[saveArray addObject:self.weapon];
	for (int i = 0; i < CREATURE_NUM_TREES; i++)
		[saveArray addObject:self.implements[i]];
	[saveArray addObject:@(self.armors.count)];
	for (int i = 0; i < self.armors.count; i++)
		[saveArray addObject:self.armors[i]];
	
	//save appearance
	[saveArray addObject:@(self.gender ? 1 : 0)];
	[saveArray addObject:@(self.hairStyle)];
	[saveArray addObject:@(self.coloration)];
	
	//save variable stats
	[saveArray addObject:@(self.x)];
	[saveArray addObject:@(self.y)];
	[saveArray addObject:@(self.health)];
	[saveArray addObject:@(self.dodges)];
	[saveArray addObject:@(self.blocks)];
	[saveArray addObject:@(self.hacks)];
	
	//save status
	[saveArray addObject:@(self.forceField)];
	[saveArray addObject:@(self.forceFieldNoDegrade)];
	[saveArray addObject:@(self.stunned)];
	[saveArray addObject:@(self.extraAction)];
	[saveArray addObject:@(self.sleeping)];
	[saveArray addObject:@(self.poisoned)];
	[saveArray addObject:@(self.stealthed)];
	[saveArray addObject:@(self.damageBoosted)];
	[saveArray addObject:@(self.defenseBoosted)];
	[saveArray addObject:@(self.immunityBoosted)];
	[saveArray addObject:@(self.skating)];
	[saveArray addObject:@(self.counterBoosted)];
	[saveArray addObject:@(self.counterBoostedStrength)];
	
	//save organizational info
	[saveArray addObject:@(self.awake ? 1 : 0)];
	[saveArray addObject:@(self.storedAttack != nil ? 1 : 0)];
	if (self.storedAttack != nil)
	{
		[saveArray addObject:self.storedAttack];
		[saveArray addObject:@(self.storedAttackSlot)];
		[saveArray addObject:@(self.storedAttackX)];
		[saveArray addObject:@(self.storedAttackY)];
	}
	[saveArray addObject:@(self.cooldowns.count)];
	for (NSString *key in self.cooldowns.allKeys)
	{
		[saveArray addObject:key];
		[saveArray addObject:self.cooldowns[key]];
	}
	
	//and save it all away
	[[NSUserDefaults standardUserDefaults] setObject:saveArray forKey:name];
	self.saveFlag = false;
}
-(id)initFromName:(NSString *)name onMap:(Map *)map
{
	if (self = [super init])
	{
		NSArray *loadArray = [[NSUserDefaults standardUserDefaults] arrayForKey:name];
		int j = 0;
		
		//save identity
		_good = ((NSNumber *)loadArray[j++]).intValue == 1;
		_race = loadArray[j++];
		if (!_good)
			_enemyType = loadArray[j++];
		NSMutableArray *sT = [NSMutableArray new];
		_skillTreeLevels = [NSMutableArray new];
		for (int i = 0; i < CREATURE_NUM_TREES; i++)
		{
			[sT addObject:loadArray[j++]];
			[_skillTreeLevels addObject:loadArray[j++]];
		}
		_skillTrees = [NSArray arrayWithArray:sT];
		
		//save equipment
		_weapon = loadArray[j++];
		_implements = [NSMutableArray new];
		for (int i = 0; i < CREATURE_NUM_TREES; i++)
			[_implements addObject:loadArray[j++]];
		int nArmors = ((NSNumber *)loadArray[j++]).intValue;
		_armors = [NSMutableArray new];
		for (int i = 0; i < nArmors; i++)
			[_armors addObject:loadArray[j++]];
		
		//save appearance
		_gender = ((NSNumber *)loadArray[j++]).intValue == 1;
		_hairStyle = ((NSNumber *)loadArray[j++]).intValue;
		_coloration = ((NSNumber *)loadArray[j++]).intValue;
		
		//save variable stats
		_x = ((NSNumber *)loadArray[j++]).intValue;
		_y = ((NSNumber *)loadArray[j++]).intValue;
		_health = ((NSNumber *)loadArray[j++]).intValue;
		_dodges = ((NSNumber *)loadArray[j++]).intValue;
		_blocks = ((NSNumber *)loadArray[j++]).intValue;
		_hacks = ((NSNumber *)loadArray[j++]).intValue;
		
		//save status
		_forceField = ((NSNumber *)loadArray[j++]).intValue;
		_forceFieldNoDegrade = ((NSNumber *)loadArray[j++]).intValue;
		_stunned = ((NSNumber *)loadArray[j++]).intValue;
		_extraAction = ((NSNumber *)loadArray[j++]).intValue;
		_sleeping = ((NSNumber *)loadArray[j++]).intValue;
		_poisoned = ((NSNumber *)loadArray[j++]).intValue;
		_stealthed = ((NSNumber *)loadArray[j++]).intValue;
		_damageBoosted = ((NSNumber *)loadArray[j++]).intValue;
		_defenseBoosted = ((NSNumber *)loadArray[j++]).intValue;
		_immunityBoosted = ((NSNumber *)loadArray[j++]).intValue;
		_skating = ((NSNumber *)loadArray[j++]).intValue;
		_counterBoosted = ((NSNumber *)loadArray[j++]).intValue;
		_counterBoostedStrength = ((NSNumber *)loadArray[j++]).intValue;
		
		//save organizational info
		_awake = ((NSNumber *)loadArray[j++]).intValue == 1;
		if (((NSNumber *)loadArray[j++]).intValue == 1)
		{
			_storedAttack = loadArray[j++];
			_storedAttackSlot = ((NSNumber *)loadArray[j++]).intValue;
			_storedAttackX = ((NSNumber *)loadArray[j++]).intValue;
			_storedAttackY = ((NSNumber *)loadArray[j++]).intValue;
		}
		else
			_storedAttack = nil;
		int nCooldowns = ((NSNumber *)loadArray[j++]).intValue;
		_cooldowns = [NSMutableDictionary new];
		for (int i = 0; i < nCooldowns; i++)
		{
			NSString *key = loadArray[j++];
			NSNumber *cooldown = loadArray[j++];
			_cooldowns[key] = cooldown;
		}
		
		//init misc
		_saveFlag = false;
		_map = map;
		
		//put yourself into the appropriate tile (if you aren't dead already)
		if (_health > 0)
			((Tile *)map.tiles[_y][_x]).inhabitant = self;
	}
	return self;
}

#pragma mark: main initializers

-(id)initWithX:(int)x andY:(int)y onMap:(Map *)map ofEnemyType:(NSString *)type
{
	if (self = [super init])
	{
		_enemyType = type;
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
		
		
		//level up skills uniformly based on the floor number
		//the first skill is leveled up first, then the second, etc
		//since the first skill is probably the one with any special abilities in it, and whatnot
		for (int i = 0; i < map.floorNum; i++)
		{
			int skillNum = i / 3;
			_skillTreeLevels[skillNum] = @(((NSNumber *)_skillTreeLevels[skillNum]).intValue + 1);
		}
		
		
		_x = x;
		_y = y;
		_map = map;
		
		[self initializeMisc];
		
	}
	return self;
}

-(int)maxAppearanceNumber
{
	return (int)loadValueArray(@"Races", self.race, @"colorations").count * loadValueNumber(@"Races", self.race, @"hair styles").intValue * 2;
}

-(id)initWithRace:(NSString *)race skillTrees:(NSArray *)skillTrees andAppearanceNumber:(int)appearanceNumber
{
	if (self = [super init])
	{
		_race = race;
		
		_armors = [NSMutableArray arrayWithObjects:@"", @"", @"", nil];
		
		//get racial armor
		_armors[0] = loadValueString(@"Races", race, @"race start armor");
		
		_skillTrees = skillTrees;
		_skillTreeLevels = [NSMutableArray arrayWithObjects:@(1), @(1), @(1), @(1), @(1), nil];
//		_skillTreeLevels = [NSMutableArray arrayWithObjects:@(4), @(4), @(4), @(4), @(4), nil];
		_implements = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", nil];
		_weapon = loadValueString(@"Races", _race, @"race start weapon");
		
		//load starting implements for your skill trees
		NSArray *implements = loadArrayEntry(@"Lists", @"starting implements");
		for (int i = 0; i < _implements.count; i++)
		{
			NSString *skillTree = _skillTrees[i];
			if (skillTree.length > 0 && loadValueBool(@"SkillTrees", skillTree, @"implement"))
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
		
		_x = 0;
		_y = 0;
		_map = nil;
		_awake = false;
        
		
        //TODO: quickstart
		_skillTrees = [NSArray arrayWithObjects:@"energy", @"sacred light", @"dagger", @"shield", @"conditioning", nil];
		_skillTreeLevels = [NSMutableArray arrayWithObjects:@(3), @(1), @(3), @(4), @(1), nil];
		_implements = [NSMutableArray arrayWithObjects:@"ether dynamics", @"glowing orb", @"stiletto", @"kite shield", @"", nil];
		_armors = [NSMutableArray arrayWithObjects:@"rusty armor", @"riveted helmet", @"cheap shoes", nil];
		_weapon = @"flail";
		
        
		
		[self initializeMisc];
		
		//get appearance from appearance number
		int numHairstyles = loadValueNumber(@"Races", self.race, @"hair styles").intValue;
		int numColorations = (int)loadValueArray(@"Races", self.race, @"colorations").count;
		self.gender = appearanceNumber >= numHairstyles * numColorations;
		appearanceNumber = appearanceNumber % (numHairstyles * numColorations);
		self.coloration = appearanceNumber / numHairstyles;
		appearanceNumber = appearanceNumber % numHairstyles;
		self.hairStyle = appearanceNumber;
		
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

-(void) breakStealth
{
	if (self.stealthed > 0)
	{
		self.stealthed = 0;
		[self.map.delegate updateCreature:self];
	}
}

-(void) invalidateCache
{
	self.cached = [NSMutableDictionary new];
}

-(void) recharge
{
	[self invalidateCache];
	
	//base variables
	self.health = self.maxHealth;
	self.dodges = self.maxDodges;
	self.blocks = self.maxBlocks;
	self.hacks = self.maxHacks;
	
	//initialize cooldown dict
	self.cooldowns = [NSMutableDictionary new];
	
	//status effect flags
	self.forceField = 0;
	self.forceFieldNoDegrade = 0;
	self.stunned = 0;
	self.extraAction = 0;
	self.poisoned = 0;
	self.sleeping = 0;
	self.stealthed = 0;
	self.damageBoosted = 0;
	self.defenseBoosted = 0;
	self.immunityBoosted = 0;
	self.skating = 0;
	self.counterBoosted = 0;
	
	self.saveFlag = YES;
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
	else if (loadValueBool(@"Attacks", attack, @"range"))
		[properties addObject:[NSString stringWithFormat:@"%i range", loadValueNumber(@"Attacks", attack, @"range").intValue]];
	else
		[properties addObject:@"Self-targeting"];
	if (loadValueBool(@"Attacks", attack, @"area"))
	{
		int area = loadValueNumber(@"Attacks", attack, @"area").intValue;
		if (!loadValueBool(@"Attacks", attack, @"instant area"))
			[properties addObject:@"delayed"];
		if (loadValueBool(@"Attacks", attack, @"line area"))
			[properties addObject:@"line attack"];
		else if (area > 1)
			[properties addObject:[NSString stringWithFormat:@"%ix%i area", area, area]];
	}
	if (!loadValueBool(@"Attacks", attack, @"dodgeable"))
		[properties addObject:@"undodgeable"];
	if (!loadValueBool(@"Attacks", attack, @"blockable"))
		[properties addObject:@"unblockable"];
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
	{
		int extra = loadValueNumber(@"Attacks", attack, @"extra actions").intValue;
		if (extra == 1)
			[properties addObject:@"doesn't take an action"];
		else
			[properties addObject:[NSString stringWithFormat:@"gives %i extra actions", extra]];
	}
	
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
	if (armor.length == 0)
		return @"nothing";
	
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
-(NSString *)stringTranslate:(NSString *)string
{
	string = [string stringByReplacingOccurrencesOfString:@"!he" withString:self.gender ? @"she" : @"he"];
	string = [string stringByReplacingOccurrencesOfString:@"!He" withString:self.gender ? @"She" : @"He"];
	string = [string stringByReplacingOccurrencesOfString:@"!man" withString:self.gender ? @"woman" : @"man"];
	string = [string stringByReplacingOccurrencesOfString:@"!his" withString:self.gender ? @"her" : @"his"];
	return string;
}
-(NSString *)treeDescription:(NSString *)tree atLevel:(int)level
{
	NSString *skillDesc = [self stringTranslate:loadValueString(@"SkillTrees", tree, @"description")];
	
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
		if (skillDict[@"attack bonus"] != nil)
			[passives addObject:[NSString stringWithFormat:@"+%i%% damage to normal attacks", ((NSNumber *)skillDict[@"attack bonus"]).intValue]];
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
		if (skillDict[@"counter"] != nil)
			[passives addObject:[NSString stringWithFormat:@"%i damage counter-attack", ((NSNumber *)skillDict[@"counter"]).intValue]];
		[desc appendString:[NSString stringWithFormat:@"\n%@ level will grant you:\n", level == 0 ? @"First" : @"Next"]];
		[desc appendString:[passives componentsJoinedByString:@", "]];
		
		if (skillDict[@"attack"] != nil)
			[desc appendFormat:@"\n\nLearn the attack %@", [self attackDescription:skillDict[@"attack"]]];
		if (skillDict[@"recipies"] != nil)
			[desc appendString:@"\n\nUnlocks new recipies."];
	}
	return desc;
}

#pragma mark: attack cache stuff
//TODO: this stuff is probably unnecessary now, so it's all disabled

-(NSString *)attackCacheLoadString:(NSString *)attack fromValue:(NSString *)value
{
//	id loaded = [self attackCacheLoad:attack fromValue:value];
//	assert([loaded isKindOfClass:[NSString class]]);
//	return loaded;
	return loadValueString(@"Attacks", attack, value);
}
-(int)attackCacheLoadInt:(NSString *)attack fromValue:(NSString *)value
{
//	id loaded = [self attackCacheLoad:attack fromValue:value];
//	assert([loaded isKindOfClass:[NSNumber class]]);
//	return ((NSNumber *)loaded).intValue;
	return loadValueNumber(@"Attacks", attack, value).intValue;
}
-(BOOL)attackCacheLoadBool:(NSString *)attack fromValue:(NSString *)value
{
//	id loaded = [self attackCacheLoad:attack fromValue:value];
//	return loaded != nil;
	return loadValueBool(@"Attacks", attack, value);
}
//-(id)attackCacheLoad:(NSString *)attack fromValue:(NSString *)value
//{
//	//remake the cache if necessary
//	if (self.attackCacheName == nil || ![self.attackCacheName isEqualToString:attack])
//	{
//		self.attackCacheName = attack;
//		self.attackCache = [NSMutableDictionary new];
//	}
//	
//	//load from the cache
//	id loaded = self.attackCache[value];
//	if (loaded != nil)
//	{
//		if ([loaded isEqual:[NSNull null]])
//			return nil;
//		return loaded;
//	}
//	
//	//load from the plists
//	if (!loadValueBool(@"Attacks", attack, value))
//	{
//		self.attackCache[value] = [NSNull null];
//		return nil;
//	}
//	else
//	{
//		loaded = loadValue(@"Attacks", attack, value);
//		self.attackCache[value] = loaded;
//		return loaded;
//	}
//}

#pragma mark: enemy type stuff
-(NSString *) ai
{
	return loadValueString(@"EnemyTypes", self.enemyType, @"ai");
}
-(NSString *) name
{
	if (self.good)
		return @"Player";
	else
		return [self.enemyType capitalizedString];
}
-(NSString *) typeDescription
{
	return [self stringTranslate:loadValueString(@"EnemyTypes", self.enemyType, @"description")];
}
-(NSString *) typeDefeatMessage
{
	return [self stringTranslate:loadValueString(@"EnemyTypes", self.enemyType, @"defeat message")];
}
-(int) aiWakeDistance
{
	return loadValueNumber(@"AIs", self.ai, @"wake distance").intValue;
}
-(int) aiStealthSightDistance
{
	if (!loadValueBool(@"AIs", self.ai, @"stealth sight distance"))
		return 1;
	return loadValueNumber(@"AIs", self.ai, @"stealth sight distance").intValue;
}
-(int) aiSightDistance
{
	return loadValueNumber(@"AIs", self.ai, @"sight distance").intValue;
}
-(BOOL) aiFlee
{
	return loadValueBool(@"AIs", self.ai, @"flee during overtime");
}
-(BOOL) aiAttack
{
	return loadValueBool(@"AIs", self.ai, @"can attack");
}
-(BOOL) aiWalk
{
	return loadValueBool(@"AIs", self.ai, @"do ai walk");
}
-(BOOL) aiPath
{
	return loadValueBool(@"AIs", self.ai, @"pathfinding radius");
}
-(int) aiPathRadius
{
	return loadValueNumber(@"AIs", self.ai, @"pathfinding radius").intValue;
}
-(BOOL) aiDefend
{
	return loadValueBool(@"AIs", self.ai, @"can defend");
}
-(BOOL) aiSkate
{
	return loadValueBool(@"AIs", self.ai, @"skate ability");
}

#pragma mark: public interface functions

-(NSString *) elementForAttack:(NSString *)attack
{
	int treeNum = [self findTreeNumberOfAttack:attack];
	NSString *implement;
	if (treeNum == -1)
		implement = self.weapon;
	else
		implement = self.implements[treeNum];
	if (!loadValueBool(@"Attacks", attack, @"element"))
		return nil;
	if (implement.length > 0 && loadValueBool(@"Implements", implement, @"element"))
		return loadValueString(@"Implements", implement, @"element");
	return loadValueString(@"Attacks", attack, @"element");
}

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


//POSSIBLE IDEA:
//make an "attack" object that exists just to cache attack values? I dunno

-(BOOL) validTargetSpotFor:(NSString *)attack atX:(int)x andY:(int)y openSpotsAreFine:(BOOL)openSpots
{
	//set openSpotsAreFine to true if you want to find any place you can theoretically attack, not just places with people to hit
	
	if (![self attackCacheLoadBool:attack fromValue:@"range"])
	{
		//it's a 0-range attack
		//so it can only target your own square
		return (x == self.x && y == self.y);
	}
	else
	{
		//are you in range?
		int range = [self attackCacheLoadInt:attack fromValue:@"range"];
		int minRange = 1;
		if ([self attackCacheLoadBool:attack fromValue:@"min range"])
			minRange = [self attackCacheLoadInt:attack fromValue:@"min range"];
		int distance = ABS(x - self.x) + ABS(y - self.y);
		if (distance > range || distance < minRange)
			return false;
		
		//make sure it's not a solid wall
		Tile *targetTile = self.map.tiles[y][x];
		if (targetTile.solid)
			return false;
		
		//check for line of sight (if you're offscreen it's assumed that you can't hit them)
		Tile *tile = self.map.tiles[self.y][self.x];
		if (tile != targetTile && (!tile.visible || !targetTile.visible))
			return false;
        
        BOOL teleport = [self attackCacheLoadBool:attack fromValue:@"teleport"];
        if (teleport && tile.inhabitant != nil && [tile.inhabitant.race isEqualToString:@"guardian"])
            return false; //you cannot use teleport attacks on guardians, for balance reasons
		
		//line attacks must attack in cardinal directions
		if (x != self.x && y != self.y && [self attackCacheLoadBool:attack fromValue:@"line area"])
			return false;
		
		if (openSpots || //if you're looking for in-range spots
			(teleport && ![self attackCacheLoadBool:attack fromValue:@"power"])) //damaging teleports are used normally
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
	if ([self attackCacheLoadBool:attack fromValue:@"area"])
		radius = ([self attackCacheLoadInt:attack fromValue:@"area"] - 1) / 2;
	int startX = MAX(x - radius, 0);
	int startY = MAX(y - radius, 0);
	int endX = MIN(x + radius, self.map.width - 1);
	int endY = MIN(y + radius, self.map.height - 1);
	
	if ([self attackCacheLoadBool:attack fromValue:@"line area"])
	{
		//line areas are a much different thing, that work by different rules
		int range = [self attackCacheLoadInt:attack fromValue:@"range"];
		if (x < self.x)
		{
			startX = self.x - range;
			endX = self.x - 1;
		}
		else if (x > self.x)
		{
			startX = self.x + 1;
			endX = self.x + range;
		}
		else if (y < self.y)
		{
			startY = self.y - range;
			endY = self.y - 1;
		}
		else
		{
			startY = self.y + 1;
			endY = self.y + range;
		}
	}
	
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

-(int) findTreeNumberOfAttack:(NSString *)name
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
	return treeNum;
}

-(void) useAttackWithName:(NSString *)name onX:(int)x andY:(int)y
{
	int treeNum = [self findTreeNumberOfAttack:name];
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
	
	__weak typeof(self) weakSelf = self;
	if (!loadValueBool(@"Attacks", name, @"area") || loadValueBool(@"Attacks", name, @"instant area"))
		[self unleashAttackWithBlock:
		^()
		{
			[weakSelf.map update];
		}];
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
	
	//grant extra actions
	if (loadValueBool(@"Attacks", name, @"extra actions"))
		self.extraAction += loadValueNumber(@"Attacks", name, @"extra actions").intValue;
	
	int cooldown = loadValueNumber(@"Attacks", name, @"cooldown").intValue;
	if (cooldown == 1)
		cooldown = 0; //things marked as having a cooldown of 1 should have a "real" cooldown of 0
	else
		cooldown = MAX(1, cooldown - self.delayReduction);
	self.cooldowns[name] = @(cooldown);
	
	if (self.good)
		[self.map.delegate updateStats];
}

-(void) unleashAttackWithBlock:(void (^)(void))block
{
	//get the implement
	BOOL isNormalAttack = [self.storedAttack isEqualToString:@"attack"];
	NSString *implement = @"";
	if (isNormalAttack) //the implement should be your weapon
		implement = self.weapon;
	else
		implement = self.implements[self.storedAttackSlot];
	
	
	//get the power
	int power = self.damageBonus + [self bonusFromImplement:implement withName:@"power"];
	
	//if this is a normal attack, apply attack bonus also
	if (isNormalAttack)
		power += self.attackBonus;
	
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
	
	//get the suffix (for attacks)
	NSString *suffix = nil;
	if ([self.storedAttack isEqualToString:@"attack"])
		suffix = implement.length == 0 ? @"unarmed" : [NSString stringWithFormat:@"with %@", implement];
	
	//use the map's delegate stuff to do an attack anim
	__weak typeof(self) weakSelf = self;
	[self.map.delegate attackAnimation:self.storedAttack withElement:element suffix:suffix andAttackEffect:attackEffect fromPerson:self targetX:self.storedAttackX andY:self.storedAttackY withEffectBlock:
	^(void (^finalBlock)(void))
	{
		__block Creature *counterAttacker = nil;
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
					BOOL wasAsleep = hit.sleeping > 0;
					NSString *hitResult = [hit takeAttack:weakSelf.storedAttack withPower:power andElement:element inStealth:weakSelf.stealthed > 0];
					[labels addObject:hitResult];
					[creatures addObject:hit];
					if (hit.dead)
					{
						//you killed someone!
						[weakSelf killBoostsForKillingEnemyOfRace:hit.race];
						
						//remove the dead person from the map
						[hit kill];
					}
					else if (!wasAsleep && hit.sleeping == 0 && hit.stunned == 0 && !hit.dead && //inactive people can't counter
							 ABS(weakSelf.x - hit.x) + ABS(weakSelf.y - hit.y) == 1 && //can only counter in melee
							 hit.good != weakSelf.good && //don't counter allies
							 hit.counter > 0) //you need a counter-attack to counter obviously
					{
						//they might get a counter-attack in!
						if (counterAttacker == nil || counterAttacker.counter < hit.counter)
							counterAttacker = hit;
					}
				}
				
				if (hit.good)
					[weakSelf.map.delegate updateStats];
			}
			
		} forAttack:weakSelf.storedAttack onX:weakSelf.storedAttackX andY:weakSelf.storedAttackY];
		
		//cancel stealth
		if (!loadValueBool(@"Attacks", weakSelf.storedAttack, @"stealth"))
			[weakSelf breakStealth];
		
		
		if (tilesChanged)
			[weakSelf.map.delegate updateTiles];
		
		BOOL teleport = loadValueBool(@"Attacks", weakSelf.storedAttack, @"teleport");
		weakSelf.storedAttack = nil;
		
		UIColor *color = loadColorFromName([NSString stringWithFormat:@"element %@", element]);
		
		
		[weakSelf.map.delegate floatLabelsOn:creatures withString:labels andColor:color withBlock:
		^()
		{
			//teleport now, so the damage labels are on the right spot
			if (teleport)
			{
				Tile *tile = weakSelf.map.tiles[weakSelf.storedAttackY][weakSelf.storedAttackX];
				Creature *hit = tile.inhabitant;
				if (hit != nil)
				{
					((Tile *)weakSelf.map.tiles[weakSelf.y][weakSelf.x]).inhabitant = hit;
					hit.x = weakSelf.x;
					hit.y = weakSelf.y;
				}
				else
					((Tile *)weakSelf.map.tiles[weakSelf.y][weakSelf.x]).inhabitant = nil;
				tile.inhabitant = weakSelf;
				weakSelf.x = weakSelf.storedAttackX;
				weakSelf.y = weakSelf.storedAttackY;
				
				//for simplicity's sake, teleport attacks cannot trigger counters
				counterAttacker = nil;
			}
			
			
			if (counterAttacker == nil)
				finalBlock();
			else
			{
				//get the race's counter attack, or the generic "counter" if it doesn't have one
				NSString *virtualCounter;
				if (loadValueBool(@"Races", counterAttacker.race, @"racial counter attack"))
					virtualCounter = loadValueString(@"Races", counterAttacker.race, @"racial counter attack");
				else
					virtualCounter = @"counter";
				
				NSString *element = loadValueString(@"Attacks", virtualCounter, @"element");
				NSString *attackEffect = loadValueString(@"Attacks", virtualCounter, @"attack effect");
				
				NSLog(@"Counter element = %@", element);
				
				[weakSelf.map.delegate attackAnimation:virtualCounter withElement:element suffix:nil andAttackEffect:attackEffect fromPerson:counterAttacker targetX:weakSelf.x andY:weakSelf.y withEffectBlock:
				^(void (^nevermind)(void))
				{
					weakSelf.health = MAX(0, weakSelf.health - counterAttacker.counter);
					if (weakSelf.health == 0)
					{
						//yes, counter-attacks can kill you
						[counterAttacker killBoostsForKillingEnemyOfRace:weakSelf.race];
						[weakSelf kill];
					}
					
					UIColor *color = loadColorFromName([NSString stringWithFormat:@"element %@", element]);
					[weakSelf.map.delegate floatLabelsOn:[NSArray arrayWithObject:weakSelf] withString:[NSArray arrayWithObject:[NSString stringWithFormat:@"%i", counterAttacker.counter]] andColor:color withBlock:finalBlock];
				} andEndBlock:nil];
				
				//note that this is DISCARDING the new final block, because I don't want to double-skip turns, so no teleport counters
			}
		}];
	} andEndBlock:block];
}

-(void)kill
{
	((Tile *)self.map.tiles[self.y][self.x]).inhabitant = nil;
	[self.map.delegate updateCreature:self];
	
	if (self.storedAttack != nil)
	{
		[self applyBlock:
		^(Tile *tile)
		{
			[tile.aoeTargeters removeObject:self];
			tile.changed = true;
		} forAttack:self.storedAttack onX:self.storedAttackX andY:self.storedAttackY];
		[self.map.delegate updateTiles];
	}
}

-(void)killBoostsForKillingEnemyOfRace:(NSString *)race
{
	self.blocks = MIN(self.blocks + 1, self.maxBlocks);
	//TODO: any other bennies for getting a kill
	
	if (!self.good)
	{
		//add some kill credit!
		NSMutableDictionary *killsPerRace = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"statistics kills"]];
		int kills = ((NSNumber *)killsPerRace[race]).intValue;
		killsPerRace[race] = @(kills + 1);
		[[NSUserDefaults standardUserDefaults] setObject:killsPerRace forKey:@"statistics kills"];
	}
}

-(BOOL) moveWithX:(int)x andY:(int)y
{
	return [self moveWithX:x andY:y withSkate:self.skating > 0];
}

-(BOOL) moveWithX:(int)x andY:(int)y withSkate:(BOOL)skate
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
		[tile saveWithX:self.x andY:self.y];
		
		return true;
	}
	else if (!tile.solid && tile.inhabitant == nil)
	{
		tile.inhabitant = self;
		oldTile.inhabitant = nil;
		self.x += x;
		self.y += y;
		if (self.good && !skate)
			[self.map.delegate updateStats];
		
		//if you're skating, double-move
		if (skate)
			return [self moveWithX:x andY:y withSkate:false] || true;
		return true;
	}
	return false;
}

-(NSString *) takeAttack:(NSString *)attackType withPower:(int)power andElement:(NSString *)element inStealth:(BOOL)inStealth
{
	self.saveFlag = true;
	
	if (!self.good && !self.awake)
	{
		//this is for if someone is somehow hit while asleep (for instance, by a stealthy player, or with a big AoE)
		NSLog(@"Woken by touch!");
		self.awake = true;
		[self wakeUpNearby];
	}
	
	BOOL wasAsleep = false;
	if (self.sleeping > 0)
	{
		wasAsleep = true;
		self.sleeping = 0;
	}
	
	NSString *label = @"";
	
	if (!loadValueBool(@"Attacks", attackType, @"friendly"))
	{
		//don't apply damage, dodge, block, etc on friendly attacks
		if (!wasAsleep && !inStealth)
		{
			//you can't dodge or block attacks while asleep, and you can't dodge or block stealthed people
			if (loadValueBool(@"Attacks", attackType, @"dodgeable") && self.dodges > 0)
			{
				self.dodges -= 1;
				//TODO: dodge sound effect
				return @"DODGE";
			}
			
			if (loadValueBool(@"Attacks", attackType, @"blockable") && self.blocks > 0)
			{
				self.blocks -= 1;
				//TODO: block sound effect
				return @"BLOCK";
			}
		}
		
		if (loadValueBool(@"Attacks", attackType, @"power"))
		{
			//apply damage
			int basePower = loadValueNumber(@"Attacks", attackType, @"power").intValue;
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
			
			if (self.defenseBoosted > 0)
				finalPower = (finalPower * CREATURE_DEFENSE_BOOST) / 100;
			
			if (inStealth)
				finalPower = (finalPower * CREATURE_STEALTH_MULT) / 100;
			
			if (!self.good)
				finalPower = (finalPower * CREATURE_BADGUY_DAMAGE_TAKEN_MULT) / 100;
			else
				finalPower = (finalPower * CREATURE_BADGUY_DAMAGE_DONE_MULT) / 100;
			
			if (resistance < 0)
				finalPower = (power * finalPower) * (100 - resistance * CREATURE_RESISTANCEFACTOR) / (100 * 100);
			else
				finalPower = (power * finalPower) / (100 + resistance * CREATURE_RESISTANCEFACTOR);
			
			finalPower = MAX(finalPower, basePower > 0 ? 1 : 0);
			
			if (self.forceField >= finalPower && basePower > 0)
			{
				self.forceField -= finalPower;
				//TODO: block sound effect
				label = @"BLOCK";
				[self.map.delegate updateCreature:self];
			}
			else
			{
				if (self.forceField > 0 && basePower > 0)
				{
					finalPower -= self.forceField;
					self.forceField = 0;
				}
				
				label = [NSString stringWithFormat:@"%i", finalPower];
				self.health = MAX(self.health - finalPower, 0);
			}
		}
	}
	
	NSString *oldAoe = self.storedAttack;
	
	//apply (negative) status effects
	if (self.immunityBoosted == 0)
	{
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
			self.poisoned = loadValueNumber(@"Attacks", attackType, @"poison").intValue;
	}
	
	//apply special effects
	if (loadValueBool(@"Attacks", attackType, @"interrupt aoe"))
		self.storedAttack = nil;
	if (loadValueBool(@"Attacks", attackType, @"dodge restore"))
		self.dodges = MIN(self.dodges + loadValueNumber(@"Attacks", attackType, @"dodge restore").intValue, self.maxDodges);
	if (loadValueBool(@"Attacks", attackType, @"forcefield"))
	{
		int forceFieldPower = loadValueNumber(@"Attacks", attackType, @"forcefield").intValue;
		forceFieldPower = (forceFieldPower * power) / 100;
		self.forceField += forceFieldPower;
		self.forceFieldNoDegrade = CREATURE_FORCEFIELDNODEGRADE;
		[self.map.delegate updateCreature:self];
	}
	if (loadValueBool(@"Attacks", attackType, @"raise counter"))
	{
		int counterPower = loadValueNumber(@"Attacks", attackType, @"raise counter").intValue;
		counterPower = (counterPower * power) / 100;
		self.counterBoostedStrength = counterPower;
		self.counterBoosted = CREATURE_COUNTERBOOSTLENGTH;
		[self.map.delegate updateCreature:self];
	}
	if (loadValueBool(@"Attacks", attackType, @"stealth"))
	{
		self.stealthed += loadValueNumber(@"Attacks", attackType, @"stealth").intValue;
		[self.map.delegate updateCreature:self];
	}
	
	if (self.storedAttack == nil && oldAoe != nil && !self.good)
	{
		//remove the markers
		[self applyBlock:
		^(Tile *tile)
		{
			[tile.aoeTargeters removeObject:self];
			tile.changed = true;
		} forAttack:oldAoe onX:self.storedAttackX andY:self.storedAttackY];
		[self.map.delegate updateTiles];
	}
	
	return label;
}

-(void) wakeUpNearby
{
	//wake distance is an AI variable
	//so some AIs are "louder" than others
	int wakeDistance = self.aiWakeDistance;
	
	for (int y = self.y - wakeDistance; y <= self.y + wakeDistance; y++)
		for (int x = self.x - wakeDistance; x <= self.x + wakeDistance; x++)
			if (x >= 0 && y >= 0 && x < self.map.width && y < self.map.height)
			{
				Tile *tile = self.map.tiles[y][x];
				if (tile.inhabitant != nil && !tile.inhabitant.good && !tile.inhabitant.awake)
				{
					NSLog(@"Woken by hearing!");
					tile.inhabitant.awake = true;
				}
			}
}

-(BOOL) startTurn
{
	self.saveFlag = true;
	
	Tile *tile = self.map.tiles[self.y][self.x];
	
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
			if (tile.visible)
			{
				[self.map.delegate floatLabelsOn:[NSArray arrayWithObject:self] withString:[NSArray arrayWithObject:[NSString stringWithFormat:@"%i", pDamage]] andColor:loadColorFromName(@"element no element") withBlock:
				^()
				{
					if (![weakSelf startTurnInner])
						[weakSelf.map update];
				}];
				return true;
			}
			else
				return [self startTurnInner];
		}
		else //the poison runs its course instantly
			self.poisoned = 0;
	}
	
	if (self.sleeping > 0)
	{
		if (tile.visible)
		{
			[self.map.delegate floatLabelsOn:[NSArray arrayWithObject:self] withString:[NSArray arrayWithObject:@"Z"] andColor:loadColorFromName(@"element no damage") withBlock:
			^()
			{
				if (![weakSelf startTurnInner])
					[weakSelf.map update];
			}];
			return true;
		}
		else
			return [self startTurnInner];
	}
	
	return [self startTurnInner];
}

-(BOOL) startTurnInner
{
	if (self.storedAttack != nil)
	{
		__weak typeof(self) weakSelf = self;
		[self unleashAttackWithBlock:
		^()
		{
			if (![weakSelf startTurnInnerer])
				[weakSelf.map update]; //force it to update again
			else if (weakSelf.good)
				[weakSelf.map.delegate presentRepeatPrompt]; //present the repeat prompt
		}];
		return YES;
	}
	else
		return [self startTurnInnerer];
}

-(BOOL) startTurnInnerer
{
	NSLog(@"Turn started for %@", self.good ? @"player" : self.name);
	
	Tile *tile = self.map.tiles[self.y][self.x];
	
	if (self.map.overtime && !self.good && !self.awake)
	{
		NSLog(@"Woken by fear!");
		self.awake = true; //automatically wake up in overtime
	}
	
	if (self.awake && self.sleeping > 0)
		self.awake = false; //sleeping also makes your AI sleep
	
	//wake up when the player gets onscreen, unless they are stealthed
	if (!self.awake && !self.good && tile.visible)
	{
		int distance = ABS(self.x - self.map.player.x) + ABS(self.y - self.map.player.y);
		if (distance <= (self.map.player.stealthed == 0 ? self.aiSightDistance : self.aiStealthSightDistance))
		{
			NSLog(@"Woken by sight!");
			self.awake = true;
			[self wakeUpNearby];
		}
	}
	
	if (!self.map.overtime)
	{
		//TODO: awake ais who spend too many rounds offscreen (this should probably be an AI variable) should go asleep again
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
	
	
	if (self.extraAction > 0)
		self.extraAction -= 1;
	else
	{
		//status effects don't degrade when using extra-action turns, nor do cooldowns go down
		
        BOOL remakeSprite = false;
        
		if (self.forceField > 0)
		{
			if (self.forceFieldNoDegrade > 0)
				self.forceFieldNoDegrade -= 1;
			else
			{
				if (self.forceField <= CREATURE_FORCEFIELDDECAY)
					self.forceField = 0;
				else
					self.forceField /= CREATURE_FORCEFIELDDECAY;
                remakeSprite = true;
			}
		}
		
		if (self.skating > 0)
		{
			self.skating -= 1;
			if (self.skating == 0)
                remakeSprite = true;
		}
		
		if (self.damageBoosted > 0)
		{
			self.damageBoosted -= 1;
			if (self.damageBoosted == 0)
                remakeSprite = true;
		}
		
		if (self.counterBoosted > 0)
		{
			self.counterBoosted -= 1;
			if (self.counterBoosted == 0)
                remakeSprite = true;
		}
		
		if (self.defenseBoosted > 0)
		{
			self.defenseBoosted -= 1;
			if (self.defenseBoosted == 0)
                remakeSprite = true;
		}
		
		if (self.immunityBoosted > 0)
		{
			self.immunityBoosted -= 1;
			if (self.immunityBoosted == 0)
                remakeSprite = true;
		}
		
		if (self.stealthed > 0)
		{
			self.stealthed -= 1;
			if (self.stealthed == 0)
                remakeSprite = true;
		}
        
        if (remakeSprite)
            [self.map.delegate updateCreature:self];
		
	
		//reduce all cooldowns
		for (NSString *attack in self.cooldowns.allKeys)
		{
			NSNumber *cooldown = self.cooldowns[attack];
			self.cooldowns[attack] = @(MAX(cooldown.intValue - 1, 0));
		}
	}
	
	if (self.awake)
	{
		//AI action
		
		if (self.map.overtime && self.aiFlee)
		{
			//during overtime, most enemies flee
			//some don't give a shit (robots, etc)
			
			//TODO: bosses SHOULDN'T flee, or execute this block at all
			//AND, if bosses have companion enemies, those shouldn't flee either (maybe just have a no-flee flag?)
			//otherwise you won't see most of them!
			
			if (!tile.visible)
			{
				//just vanish, you're fleeing
				//TODO: if I add anything that benefits from deaths that aren't caused directly by the player
				//IE loot drops or whatnot
				//I should come up with a mechanic to make an enemy vanish without killing it
				self.health = 0;
				[self kill];
				return NO;
			}
			
			//try to flee
			if ([self doAiWalk:-1])
				return YES;
			
			//otherwise, skip your turn
			//don't bother defending or anything, it's just a waste
			return NO;
		}
		
		//make a shuffled attacks array, to randomize which attacks you use
		NSMutableArray *attacks = [NSMutableArray arrayWithArray:[self attacks]];
		[attacks removeObjectAtIndex:0]; //skip attack
		shuffleArray(attacks);
		
		
		//look for an attack you can use on the player
		for (int i = 0; i < attacks.count; i++)
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
		if (self.aiAttack && [self validTargetSpotFor:@"attack" atX:self.map.player.x andY:self.map.player.y openSpotsAreFine:NO])
		{
			//use attack
			[self useAttackWithTreeNumber:0 andName:@"attack" onX:self.map.player.x andY:self.map.player.y];
			return YES;
		}
		
		//see if you can use any self-targeting attacks
		for (int i = 0; i < attacks.count; i++)
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
		if ((tile.visible || self.map.player.stealthed == 0) &&
            ABS(self.x - self.map.player.x) + ABS(self.y - self.map.player.y) > 1) //don't move if you're next to them
		{
			//which kinds of walk should you try?
			BOOL tryAIWalk = self.aiWalk;
			BOOL tryPathWalk = self.aiPath;
			
			if (tryPathWalk && !tile.visible)
				tryAIWalk = false; //only path walk when offscreen, if you have the option
			
			
			if (tryAIWalk && [self doAiWalk:1])
				return YES;
			
			if (tryPathWalk)
			{
				int pathRadius = self.aiPathRadius;
				PathDirection direction = [self.map pathFromX:self.x andY:self.y toX:self.map.player.x andY:self.map.player.y withRadius:pathRadius];
				switch(direction)
				{
					case PathDirectionMinusX:
						if ([self.map movePerson:self withX:-1 andY:0])
                            return YES;
					case PathDirectionPlusX:
						if ([self.map movePerson:self withX:1 andY:0])
                            return YES;
					case PathDirectionMinusY:
						if ([self.map movePerson:self withX:0 andY:-1])
                            return YES;
					case PathDirectionPlusY:
						if ([self.map movePerson:self withX:0 andY:1])
                            return YES;
					case PathDirectionNoPath: break;
				}
			}
		}
		
		
		//TODO: maybe smarter AIs can do some actual pathfinding, within a certain radius?
		//IE for if the player teleports away, or is behind a small wall or whatever
		
		
		//if you are stuck and onscreen, defend
		if (tile.visible && self.aiDefend)
		{
			[self useAttackWithTreeNumber:0 andName:@"defend" onX:self.x andY:self.y];
			return YES;
		}
		
		//if you can't defend, just skip your turn
		return NO;
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

-(BOOL)doAiWalk:(int)mult
{
	BOOL skateAbility = self.aiSkate;
	
	int xDif = (self.map.player.x - self.x) * mult;
	int yDif = (self.map.player.y - self.y) * mult;
	int xDir = copysign(1, xDif);
	int yDir = copysign(1, yDif);
	
	if (skateAbility)
		self.skating = 1;
	
	BOOL xFirst = ABS(xDif) > ABS(yDif);
	if (ABS(xDif) == ABS(yDif))
		xFirst = arc4random_uniform(2) == 1;
	if ([self.map movePerson:self withX:(xFirst ? xDir : 0) andY:(!xFirst ? yDir : 0)])
	{
		self.skating = 0;
		return YES;
	}
	if (xDif != 0 && yDif != 0 && [self.map movePerson:self withX:(!xFirst ? xDir : 0) andY:(xFirst ? yDir : 0)])
	{
		self.skating = 0;
		return YES;
	}
	self.skating = 0;
	return NO;
}


#pragma mark: derived statistics
-(BOOL) dead
{
	return self.health == 0;
}

-(int) damageBonus
{
	int b = [self totalBonus:@"damage bonus"];
	if (self.damageBoosted > 0)
		b = (b * CREATURE_DAMAGE_BOOST) / 100;
	return b;
}
-(int) attackBonus
{
	int b = [self totalBonus:@"attack bonus"];
	if (self.damageBoosted > 0)
		b = (b * CREATURE_DAMAGE_BOOST) / 100;
	return b;
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
-(int) counter
{
	int c = [self totalBonus:@"counter"];
	if (self.counterBoosted > 0)
		c += self.counterBoostedStrength;
	return c;
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
	if (tree.length == 0)
		return 0;
	
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
	//check to see if it's cached
	NSNumber *cachedValue = self.cached[name];
	if (cachedValue != nil)
		return cachedValue.intValue;
	
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
	
	//cache what you got
	self.cached[name] = @(bonus);
	
	return bonus;
}

@end