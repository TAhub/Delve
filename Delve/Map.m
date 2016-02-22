//
//  Map.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Map.h"
#import "Tile.h"
#import "Creature.h"

@implementation Map

-(id)init
{
	if (self = [super init])
	{
		_creatures = [NSMutableArray new];
		_tiles = [NSMutableArray new];
		
		//make initial map
		int width = 8;
		int height = 10;
		for (int y = 0; y < height; y++)
		{
			NSMutableArray *row = [NSMutableArray new];
			for (int x = 0; x < width; x++)
			{
				Tile *tile = [[Tile alloc] initWithType:((x == 0 || y == 0 || x == width - 1 || y == height - 1) ? @"wall" : @"floor")];
				[row addObject:tile];
			}
			[_tiles addObject:row];
		}
		
		//add creatures
		Creature *player = [[Creature alloc] initWithX:2 andY:2 onMap:self];
		((Tile *)_tiles[2][2]).inhabitant = player;
		Creature *enemy = [[Creature alloc] initWithX:5 andY:5 onMap:self ofEnemyType:@"ruin feeder"];
		((Tile *)_tiles[5][5]).inhabitant = enemy;
		[_creatures addObject:player];
		[_creatures addObject:enemy];
	}
	return self;
}

-(int)width
{
	return (int)((NSArray *)self.tiles[0]).count;
}
-(int)height
{
	return (int)self.tiles.count;
}

@end