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
#import "Constants.h"

@interface Map()

@property int personOn;

@end

@implementation Map

-(id)init
{
	if (self = [super init])
	{
		_creatures = [NSMutableArray new];
		_tiles = [NSMutableArray new];
		
		//make initial map
		int width = 20;
		int height = 20;
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
		_player = player;
		((Tile *)_tiles[2][2]).inhabitant = player;
		Creature *enemy = [[Creature alloc] initWithX:5 andY:5 onMap:self ofEnemyType:@"ruin feeder"];
		((Tile *)_tiles[5][5]).inhabitant = enemy;
		[_creatures addObject:player];
		[_creatures addObject:enemy];
		
		//start right before the player's turn
		_personOn = self.creatures.count - 1;
	}
	return self;
}

-(void)update
{
	[self recalculateVisibility];
	
	//keep going for next
	while (true)
	{
		self.personOn = (self.personOn + 1) % self.creatures.count;
		Creature *cr = self.creatures[self.personOn];
		if (!cr.dead && [cr startTurn])
			break;
	}
}

-(BOOL)yourTurn
{
	return self.creatures[self.personOn] == self.player;
}

-(BOOL)moveWithX:(int)x andY:(int)y
{
	if (!self.yourTurn)
		return NO;
	
	if ([self.player moveWithX:x andY:y])
	{
		__weak typeof(self) weakSelf = self;
		[self.delegate moveCreature:self.player withBlock:
		^()
		{
			[weakSelf update];
		}];
		return YES;
	}
	return NO;
}

-(void)recalculateVisibility
{
	for (NSMutableArray *row in self.tiles)
		for (Tile *tile in row)
			tile.visible = NO;
	
	//project sight-lines from the player
	//TODO: make this into a constant I guess
	int sightLineDensity = 30;
	for (int i = 0; i < sightLineDensity; i++)
	{
		float angle = M_PI * 2 * i / sightLineDensity;
		BOOL hitWall = false;
		for (int j = 0; j < MAX(GAMEPLAY_SCREEN_WIDTH, GAMEPLAY_SCREEN_HEIGHT); j++)
		{
			float x = cos(angle) * j + self.player.x;
			float y = sin(angle) * j + self.player.y;
			int rX = roundf(x);
			int rY = roundf(y);
			if (rX < 0 || rY < 0 || rX >= self.width || rY >= self.height)
				break;
			Tile *tile = self.tiles[rY][rX];
			if (tile.solid)
			{
				if (hitWall)
					break;
				hitWall = true;
			}
			tile.visible = YES;
		}
	}
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