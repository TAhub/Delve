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

-(BOOL)solid
{
	return [self.type isEqualToString:@"wall"];
}

-(UIColor *) color
{
	//TODO: if this tile is dicovered but not-visible, its color should be desaturated
	return (self.solid ? [UIColor grayColor] : [UIColor darkGrayColor]);
}

@end