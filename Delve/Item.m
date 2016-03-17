//
//  Item.m
//  Delve
//
//  Created by Theodore Abshire on 2/28/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Item.h"
#import "Creature.h"

@implementation Item

-(id)initWithName:(NSString *)name andType:(ItemType)type
{
	if (self = [super init])
	{
		_name = name;
		_type = type;
		_number = 1;
	}
	return self;
}

-(int)healing
{
	if (loadValueBool(@"InventoryItems", self.name, @"healing"))
		return loadValueNumber(@"InventoryItems", self.name, @"healing").intValue;
	return 0;
}
-(int)skateBuff
{
	if (loadValueBool(@"InventoryItems", self.name, @"skate buff"))
		return loadValueNumber(@"InventoryItems", self.name, @"skate buff").intValue;
	return 0;
}
-(int)damageBuff
{
	if (loadValueBool(@"InventoryItems", self.name, @"damage buff"))
		return loadValueNumber(@"InventoryItems", self.name, @"damage buff").intValue;
	return 0;
}
-(int)defenseBuff
{
	if (loadValueBool(@"InventoryItems", self.name, @"defense buff"))
		return loadValueNumber(@"InventoryItems", self.name, @"defense buff").intValue;
	return 0;
}
-(int)statusImmunityBuff
{
	if (loadValueBool(@"InventoryItems", self.name, @"status immunity buff"))
		return loadValueNumber(@"InventoryItems", self.name, @"status immunity buff").intValue;
	return 0;
}
-(int)invisibilityBuff
{
	if (loadValueBool(@"InventoryItems", self.name, @"invisibility buff"))
		return loadValueNumber(@"InventoryItems", self.name, @"invisibility buff").intValue;
	return 0;
}
-(int)timeBuff
{
	if (loadValueBool(@"InventoryItems", self.name, @"time buff"))
		return loadValueNumber(@"InventoryItems", self.name, @"time buff").intValue;
	return 0;
}
-(BOOL)usable
{
	return (self.healing > 0 || self.timeBuff > 0 || self.remakeSprite);
}
-(BOOL)remakeSprite
{
	return (self.damageBuff > 0 || self.statusImmunityBuff > 0 || self.invisibilityBuff > 0 || self.skateBuff > 0 || self.defenseBuff > 0);
}

-(NSString *)itemDescriptionWithCreature:(Creature *)creature
{
	switch(self.type)
	{
		case ItemTypeInventory:
			{
				NSMutableString *desc = [NSMutableString stringWithString:loadValueString(@"InventoryItems", self.name, @"description")];
				if (!self.usable)
					[desc appendFormat:@" Not usable."];
				else
				{
					if (self.healing > 0)
						[desc appendFormat:@" Heals %i health.", self.healing * creature.metabolism / 100];
					if (self.damageBuff > 0)
						[desc appendFormat:@" Raises damage for %i rounds.", self.damageBuff];
					if (self.defenseBuff > 0)
						[desc appendFormat:@" Take less damage for %i rounds.", self.defenseBuff];
					if (self.invisibilityBuff > 0)
						[desc appendFormat:@" Turn invisible for %i rounds.", self.invisibilityBuff];
					if (self.statusImmunityBuff > 0)
						[desc appendFormat:@" Immunity to status effects for %i rounds.", self.statusImmunityBuff];
					if (self.timeBuff > 0)
						[desc appendFormat:@" Grants %i extra actions.", self.timeBuff];
					if (self.skateBuff > 0)
						[desc appendFormat:@" Allows the user to move twice as fast for %i rounds.", self.skateBuff];
				}
				return desc;
			}
		case ItemTypeArmor:
			return [creature armorDescription:self.name];
		case ItemTypeImplement:
			return [creature weaponDescription:self.name];
	}
}

@end