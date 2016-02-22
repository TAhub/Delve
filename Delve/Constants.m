//
//  Constants.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Constants.h"
#import "Assert.h"

#pragma mark plist accessors

UIColor *loadColor(NSString *colorCode)
{
	assert(colorCode != nil);
	assert(colorCode.length == 6);
	
	NSString *rString = [colorCode substringToIndex:2];
	NSString *gString = [[colorCode substringFromIndex:2] substringToIndex:2];
	NSString *bString = [colorCode substringFromIndex:4];
	int r = (int)strtol([rString UTF8String], NULL, 16);
	int g = (int)strtol([gString UTF8String], NULL, 16);
	int b = (int)strtol([bString UTF8String], NULL, 16);
	
	return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1];
}
NSDictionary *loadEntries(NSString *category)
{
	NSString *p = [[NSBundle mainBundle] pathForResource:category ofType:@"plist"];
	NSDictionary *d = [[NSDictionary alloc] initWithContentsOfFile:p];
	assert(d != nil);
	return d;
}
NSDictionary *loadEntry(NSString *category, NSString *entry)
{
	NSDictionary *p = loadEntries(category);
	id e = p[entry];
	assert(e != nil);
	assert([e isKindOfClass:[NSDictionary class]]);
	return e;
}
NSArray *loadArrayEntry(NSString *category, NSString *entry)
{
	NSDictionary *p = loadEntries(category);
	id a = p[entry];
	assert(a != nil);
	assert([a isKindOfClass:[NSArray class]]);
	return a;
}
NSObject *loadValue(NSString *category, NSString *entry, NSString *value)
{
	NSDictionary *e = loadEntry(category, entry);
	id v = e[value];
	assert(v != nil);
	return v;
}
UIColor *loadValueColor(NSString *category, NSString *entry, NSString *value)
{
	return loadColor(loadValueString(category, entry, value));
}
NSNumber *loadValueNumber(NSString *category, NSString *entry, NSString *value)
{
	NSObject *v = loadValue(category, entry, value);
	assert([v isKindOfClass:[NSNumber class]]);
	return (NSNumber *)v;
}
NSString *loadValueString(NSString *category, NSString *entry, NSString *value)
{
	NSObject *v = loadValue(category, entry, value);
	assert([v isKindOfClass:[NSString class]]);
	return (NSString *)v;
}
NSArray *loadValueArray(NSString *category, NSString *entry, NSString *value)
{
	NSObject *v = loadValue(category, entry, value);
	assert([v isKindOfClass:[NSArray class]]);
	return (NSArray *)v;
}
BOOL loadValueBool(NSString *category, NSString *entry, NSString *value)
{
	//this can't use the normal loadValue because it throws an exception on nil
	NSDictionary *e = loadEntry(category, entry);
	return e[value] != nil;
}

#pragma mark tests

void passiveBalanceTest()
{
	int damageBonus = 0;
	int health = 0;
	int smashResistance = 0;
	int cutResistance = 0;
	int shockResistance = 0;
	int burnResistance = 0;
	int dodges = 0;
	int blocks = 0;
	int hacks = 0;
	int metabolism = 0;
	
	for (NSString *treeName in loadEntries(@"SkillTrees").allKeys)
		if (![loadValueString(@"SkillTrees", treeName, @"type") isEqualToString:@"invalid"])
		{
			NSArray *skills = loadValueArray(@"SkillTrees", treeName, @"skills");
			int lDamageBonus = 0;
			int lHealth = 0;
			int lSmashResistance = 0;
			int lCutResistance = 0;
			int lShockResistance = 0;
			int lBurnResistance = 0;
			int lDodges = 0;
			int lBlocks = 0;
			int lHacks = 0;
			int lMetabolism = 0;
			for (int i = 0; i < 4; i++)
			{
				NSDictionary *skill = skills[i];
				if (skill[@"damage bonus"] != nil)
					lDamageBonus += ((NSNumber *)skill[@"damage bonus"]).intValue;
				if (skill[@"health"] != nil)
					lHealth += ((NSNumber *)skill[@"health"]).intValue;
				if (skill[@"smash resistance"] != nil)
					lSmashResistance += ((NSNumber *)skill[@"smash resistance"]).intValue;
				if (skill[@"cut resistance"] != nil)
					lCutResistance += ((NSNumber *)skill[@"cut resistance"]).intValue;
				if (skill[@"shock resistance"] != nil)
					lShockResistance += ((NSNumber *)skill[@"shock resistance"]).intValue;
				if (skill[@"burn resistance"] != nil)
					lBurnResistance += ((NSNumber *)skill[@"burn resistance"]).intValue;
				if (skill[@"dodges"] != nil)
					lDodges += ((NSNumber *)skill[@"dodges"]).intValue;
				if (skill[@"blocks"] != nil)
					lBlocks += ((NSNumber *)skill[@"blocks"]).intValue;
				if (skill[@"hacks"] != nil)
					lHacks += ((NSNumber *)skill[@"hacks"]).intValue;
				if (skill[@"metabolism"] != nil)
					lMetabolism += ((NSNumber *)skill[@"metabolism"]).intValue;
			}
			
			health += lHealth;
			damageBonus += lDamageBonus;
			smashResistance += lSmashResistance;
			cutResistance += lCutResistance;
			shockResistance += lShockResistance;
			burnResistance += lBurnResistance;
			dodges += lDodges;
			blocks += lBlocks;
			hacks += lHacks;
			metabolism += lMetabolism;
			
			//calculate points
			float points = (lHealth / 25.0f) + (lDamageBonus / 25.0f) + (lSmashResistance / 2.0f) + (lCutResistance / 2.0f);
			points += (lShockResistance / 2.0f) + (lBurnResistance / 2.0f) + (lDodges) + (lBlocks) + (lHacks) + (lMetabolism / 30.0f);
			NSLog(@"Passive points for %@: %f", treeName, points);
		}
	
	NSLog(@"TOTALS:");
	NSLog(@"damage bonus = %i", damageBonus);
	NSLog(@"health = %i", health);
	NSLog(@"smash resistance = %i", smashResistance);
	NSLog(@"cut resistance = %i", cutResistance);
	NSLog(@"shock resistance = %i", shockResistance);
	NSLog(@"burn resistance = %i", burnResistance);
	NSLog(@"dodges = %i", dodges);
	NSLog(@"blocks = %i", blocks);
	NSLog(@"hacks = %i", hacks);
	NSLog(@"metabolism = %i", metabolism);
}