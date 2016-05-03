//
//  Tile.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Tile.h"
#import "Item.h"

@interface Tile()

@property BOOL opaqueInner;
@property BOOL solidInner;
@property BOOL stairsInner;
@property (strong, nonatomic) NSString *spriteNameInner;
@property BOOL valuesComputed;

@end

@implementation Tile

-(void)saveWithX:(int)x andY:(int)y
{
	NSMutableArray *saveArray = [NSMutableArray new];
	[saveArray addObject:self.type];
	[saveArray addObject:@(self.treasureType)];
	if (self.treasureType != TreasureTypeNone)
	{
		[saveArray addObject:self.treasure.name];
		[saveArray addObject:@(self.treasure.type)];
		[saveArray addObject:@(self.treasure.number)];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:saveArray forKey:[NSString stringWithFormat:@"tile %i-%i", x, y]];
}
-(id)initWithX:(int)x andY:(int)y
{
	if (self = [super init])
	{
		NSArray *loadArray = [[NSUserDefaults standardUserDefaults] arrayForKey:[NSString stringWithFormat:@"tile %i-%i", x, y]];
		_type = loadArray[0];
		_treasureType = ((NSNumber *)loadArray[1]).intValue;
		if (_treasureType != TreasureTypeNone)
		{
			NSString *name = loadArray[2];
			ItemType type = ((NSNumber *)loadArray[3]).intValue;
			int number = ((NSNumber *)loadArray[4]).intValue;
			_treasure = [[Item alloc] initWithName:name andType:type];
			_treasure.number = number;
		}
		
		[self miscInit];
	}
	return self;
}

-(id)initWithType:(NSString *)type
{
	if (self = [super init])
	{
		_type = type;
		_treasureType = TreasureTypeNone;
		_treasure = nil;
		[self miscInit];
	}
	return self;
}

-(void)miscInit
{
	self.inhabitant = nil;
	self.visible = NO;
	self.discovered = NO;
	self.aoeTargeters = [NSMutableSet new];
	self.targetLevel = TargetLevelOutOfRange;
	self.valuesComputed = false;
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
	self.stairsInner = loadValueBool(@"Tiles", self.type, @"stairs");
	self.opaqueInner = loadValueBool(@"Tiles", self.type, @"opaque");
	
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

-(BOOL) opaque
{
	if (!self.valuesComputed)
		[self computeValues];
	return self.opaqueInner;
}

-(BOOL)solid
{
	if (!self.valuesComputed)
		[self computeValues];
	return self.solidInner;
}

-(BOOL)stairs
{
	if (!self.valuesComputed)
		[self computeValues];
	return self.stairsInner;
}

-(BOOL) canUnlock
{
	return loadValueBool(@"Tiles", self.type, @"unlocks into");
}
-(void) unlock
{
	self.type = loadValueString(@"Tiles", self.type, @"unlocks into");
}

-(BOOL) canRubble
{
	return loadValueBool(@"Tiles", self.type, @"rubbles into");
}
-(void) rubble
{
	//some things only rubble occasionally
	if (loadValueBool(@"Tiles", self.type, @"rubble chance") && arc4random_uniform(100) > loadValueNumber(@"Tiles", self.type, @"rubble chance").intValue)
		return;
	
	self.type = loadValueString(@"Tiles", self.type, @"rubbles into");
}

-(UIColor *) color
{
	if (loadValueBool(@"Tiles", self.type, @"color"))
		return loadColorFromName(loadValueString(@"Tiles", self.type, @"color"));
	return nil;
}

@end