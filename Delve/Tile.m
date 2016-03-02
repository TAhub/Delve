//
//  Tile.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Tile.h"

@interface Tile()

@property BOOL solidInner;
@property (strong, nonatomic) NSString *spriteNameInner;
@property BOOL valuesComputed;

@end

@implementation Tile

-(id)initWithType:(NSString *)type
{
	if (self = [super init])
	{
		_type = type;
		_inhabitant = nil;
		_visible = NO;
		_discovered = NO;
		_aoeTargeters = [NSMutableSet new];
		_targetLevel = TargetLevelOutOfRange;
		_treasureType = TreasureTypeNone;
		_treasure = nil;
		_valuesComputed = false;
	}
	return self;
}

#pragma mark: preload values

-(void)setType:(NSString *)type
{
	_type = type;
	self.valuesComputed = false;
}

-(void)computeValues
{
	if (!loadValueBool(@"Tiles", self.type, @"sprite"))
		self.spriteNameInner = nil;
	else
		self.spriteNameInner = loadValueString(@"Tiles", self.type, @"sprite");
	self.solidInner = loadValueBool(@"Tiles", self.type, @"solid");
	
	self.valuesComputed = true;
}

-(NSString *)spriteName
{
	if (!self.valuesComputed)
		[self computeValues];
	return self.spriteNameInner;
}

-(BOOL) validPlacementSpot
{
	return self.inhabitant == nil && !self.solid && self.treasureType == TreasureTypeNone;
}

-(BOOL)solid
{
	if (!self.valuesComputed)
		[self computeValues];
	return self.solidInner;
}

-(BOOL) canUnlock
{
	return loadValueBool(@"Tiles", self.type, @"unlocks into");
}
-(void) unlock
{
	self.type = loadValueString(@"Tiles", self.type, @"unlocks into");
}

-(UIColor *) color
{
	return loadColorFromName(loadValueString(@"Tiles", self.type, @"color"));
}

@end