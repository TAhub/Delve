//
//  Tile.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Tile.h"

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
	}
	return self;
}

-(BOOL) validPlacementSpot
{
	return self.inhabitant == nil && !self.solid; //TODO: the tile should also have no items
}

-(BOOL)solid
{
	return loadValueBool(@"Tiles", self.type, @"solid");
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
	//TODO: if this tile is dicovered but not-visible, its color should be desaturated
	return loadColorFromName(loadValueString(@"Tiles", self.type, @"color"));
}

@end