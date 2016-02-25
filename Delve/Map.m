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
#import "GeneratorRoom.h"

@interface Map()

@property int personOn;

@end

@implementation Map

-(id)init
{
	if (self = [super init])
	{
		_creatures = [NSMutableArray new];
		[self mapGenerate];
		
		//start right before the player's turn
		_personOn = (int)self.creatures.count - 1;
	}
	return self;
}

-(void)update
{
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

-(void)tilesChanged
{
	[self.delegate updateTiles];
}
-(void)statsChanged
{
	[self.delegate updateStats];
}

-(BOOL)moveWithX:(int)x andY:(int)y
{
	if (!self.yourTurn)
		return NO;
	
	return [self movePerson:self.player withX:x andY:y];
}

-(BOOL)movePerson:(Creature *)person withX:(int)x andY:(int)y;
{
	if ([person moveWithX:x andY:y])
	{
		__weak typeof(self) weakSelf = self;
		[self.delegate moveCreature:person withBlock:
		^()
		{
			[weakSelf recalculateVisibility];
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
		{
			tile.lastVisible = tile.visible;
			tile.visible = NO;
		}
	
	//project sight-lines from the player
	
	BOOL visibleChanged = false;
	
	//TODO: make this into a constant I guess
	int sightLineDensity = 80;
	for (int i = 0; i < sightLineDensity; i++)
	{
		float angle = M_PI * 2 * i / sightLineDensity;
		BOOL hitWall = false;
		for (int j = 0; j < MAX(GAMEPLAY_SCREEN_WIDTH, GAMEPLAY_SCREEN_HEIGHT) * 3; j++)
		{
			float x = cos(angle) * j / 3.0f + self.player.x;
			float y = sin(angle) * j / 3.0f + self.player.y;
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
			if (!tile.discovered)
			{
				tile.discovered = YES;
				visibleChanged = YES;
			}
		}
	}
	
	if (!visibleChanged)
		for (NSMutableArray *row in self.tiles)
		{
			if (visibleChanged)
				break;
			for (Tile *tile in row)
				if (tile.lastVisible != tile.visible)
				{
					visibleChanged = YES;
					break;
				}
		}
	
	if (visibleChanged)
		[self.delegate updateTiles];
}

-(int)width
{
	return (int)((NSArray *)self.tiles[0]).count;
}
-(int)height
{
	return (int)self.tiles.count;
}

#pragma mark: map generation

-(void)mapGenerate
{
	//first, get map generator variables
	//TODO: get these from data
	int roomSize = 5;
	int rows = 10;
	int columns = 6;
	int doorsAtATime = 5;
	int minNonOrphans = 20;
	int lockedDoorChance = 50;
	int noDoorChance = 25;
	int encounters = 10;
	int desiredPathLength = 7;
	
	NSLog(@"Generating room array");
	
	//keep in mind that for the purposes of this
	//"up" is negative y, "down" is positive y
	
	//initialize room array
	NSMutableArray *rooms = [NSMutableArray new];
	for (int y = 0; y < rows; y++)
	{
		NSMutableArray *row = [NSMutableArray new];
		GeneratorRoom *lastRoom = nil;
		for (int x = 0; x < columns; x++)
		{
			GeneratorRoom *newRoom = [[GeneratorRoom alloc] initWithSize:roomSize atX:x andY:y];
			newRoom.leftRoom = lastRoom;
			if (y > 0)
				newRoom.upRoom = rooms[y-1][x];
			lastRoom = newRoom;
			[row addObject:newRoom];
		}
		
		[rooms addObject:row];
	}
	
	NSLog(@"Placing room exits");
	
	//start room is at (columns/2, rows-1)
	//end room is at (columns/2, 0)
	((GeneratorRoom *)rooms[rows-1][columns/2]).accessable = true;
	
	//TODO: should probably put in some escape clause here
	//that will retry generation after like 100 loops, just in case
	while (true)
	{
		NSLog(@"--Making connections");
		
		//add some random connections
		for (int i = 0; i < doorsAtATime; )
		{
			int x = (int)arc4random_uniform(columns);
			int y = (int)arc4random_uniform(rows);
			GeneratorRoom *room = rooms[y][x];
			int dir = (int)arc4random_uniform(4);
			switch(dir)
			{
				case 0:
					if (x > 0 && room.leftDoor == GeneratorRoomExitWall)
					{
						room.leftDoor = GeneratorRoomExitDoor;
						i += 1;
					}
					break;
				case 1:
					if (y > 0 && room.upDoor == GeneratorRoomExitWall)
					{
						room.upDoor = GeneratorRoomExitDoor;
						i += 1;
					}
					break;
				case 2:
					if (x < columns - 1 && room.rightDoor == GeneratorRoomExitWall)
					{
						room.rightDoor = GeneratorRoomExitDoor;
						i += 1;
					}
					break;
				case 3:
					if (y < rows - 1 && room.downDoor == GeneratorRoomExitWall)
					{
						room.downDoor = GeneratorRoomExitDoor;
						i += 1;
					}
					break;
			}
		}
		
		NSLog(@"--Checking accessability");
		
		//update accessability in rooms, while counting accessable rooms
		int accessableRooms = 0;
		BOOL changes = false;
		do
		{
			changes = false;
			accessableRooms = 0;
			for (int y = 0; y < rows; y++)
				for (int x = 0; x < columns; x++)
				{
					GeneratorRoom *room = rooms[y][x];
					
					if (!room.accessable)
					{
						if ((room.upDoor != GeneratorRoomExitWall && ((GeneratorRoom *)rooms[y-1][x]).accessable) ||
							(room.rightDoor != GeneratorRoomExitWall && ((GeneratorRoom *)rooms[y][x+1]).accessable) ||
							(room.downDoor != GeneratorRoomExitWall && ((GeneratorRoom *)rooms[y+1][x]).accessable) ||
							(room.leftDoor != GeneratorRoomExitWall && ((GeneratorRoom *)rooms[y][x-1]).accessable))
						{
							room.accessable = true;
							changes = true;
						}
					}
					
					if (room.accessable)
						accessableRooms += 1;
				}
		}
		while (changes);
		
		NSLog(@"----Accessable rooms: %i", accessableRooms);
		
		if (accessableRooms >= minNonOrphans && ((GeneratorRoom *)rooms[0][columns/2]).accessable)
		{
			//there are enough explorable rooms, and you can get to the exit
			//so the first phase of generation is done
			break;
		}
	}
	
	NSLog(@"Finding path");
	
	//find paths from the start to the end
	NSMutableArray *paths = [NSMutableArray new];
	NSMutableArray *pathStart = [NSMutableArray arrayWithObject:rooms[rows-1][columns/2]];
	NSArray *intendedPath = [self pathExplore:pathStart aroundRooms:rooms toExit:rooms[0][columns/2] intoPaths:paths withDesiredLength:desiredPathLength];
	if (intendedPath == nil)
	{
		NSLog(@"--No correct path found, looking for best path");
		//there was no path of EXACTLY the right length
		//so look at paths from the path list
		for (NSArray *path in paths)
			if (intendedPath == nil || ABS(path.count - desiredPathLength) < ABS(intendedPath.count - desiredPathLength))
				intendedPath = path;
	}
	
	NSLog(@"Marking doors on path");
	
	//turn every door down the intended path into a path door
	for (int i = 0; i < intendedPath.count - 1; i++)
	{
		GeneratorRoom *room = intendedPath[i];
		GeneratorRoom *nextRoom = intendedPath[i + 1];
		if (room.leftRoom == nextRoom)
			room.leftDoor = GeneratorRoomExitPathDoor;
		else if (room.upRoom == nextRoom)
			room.upDoor = GeneratorRoomExitPathDoor;
		else if (nextRoom.leftRoom == room)
			nextRoom.leftDoor = GeneratorRoomExitPathDoor;
		else
			nextRoom.upDoor = GeneratorRoomExitPathDoor;
	}
	
	NSLog(@"Adding locked doors");
	
	//turn non-path doors into locked doors
	for (NSArray *row in rooms)
		for (GeneratorRoom *room in row)
		{
			if (room.leftDoor == GeneratorRoomExitDoor && arc4random_uniform(100) < lockedDoorChance)
				room.leftDoor = GeneratorRoomExitLockedDoor;
			if (room.rightDoor == GeneratorRoomExitDoor && arc4random_uniform(100) < lockedDoorChance)
				room.rightDoor = GeneratorRoomExitLockedDoor;
			if (room.upDoor == GeneratorRoomExitDoor && arc4random_uniform(100) < lockedDoorChance)
				room.upDoor = GeneratorRoomExitLockedDoor;
			if (room.downDoor == GeneratorRoomExitDoor && arc4random_uniform(100) < lockedDoorChance)
				room.downDoor = GeneratorRoomExitLockedDoor;
		}
	
	NSLog(@"Adding no-doors");
	
	//turn normal doors into no-doors
	for (NSArray *row in rooms)
		for (GeneratorRoom *room in row)
			if (room.canAddNoDoor && arc4random_uniform(100) < noDoorChance)
			{
				int dStart = (int)arc4random_uniform(4);
				for (int i = 0; i < 4; i++)
				{
					int d = (i + dStart) % 4;
					GeneratorRoom *oRoom;
					switch(d)
					{
						case 0: oRoom = room.y <= 0 ? nil : rooms[room.y-1][room.x]; break;
						case 1: oRoom = room.y >= rows - 1 ? nil : rooms[room.y+1][room.x]; break;
						case 2: oRoom = room.x <= 0 ? nil : rooms[room.y][room.x-1]; break;
						case 3: oRoom = room.x >= columns - 1 ? nil : rooms[room.y][room.x+1]; break;
					}
					if (oRoom != nil && oRoom.canAddNoDoor)
					{
						switch(d)
						{
							case 0: room.upDoor = GeneratorRoomExitNoDoor; break;
							case 1: room.downDoor = GeneratorRoomExitNoDoor; break;
							case 2: room.leftDoor = GeneratorRoomExitNoDoor; break;
							case 3: room.rightDoor = GeneratorRoomExitNoDoor; break;
						}
						break;
					}
				}
			}
	
	//TODO: go through the rooms and identify which ones you NEED to unlock a door to get to
	//each room like that should have at least SOMETHING in it
	//other rooms can have some probability of having enemies, treasure, whatever
	
	
	NSLog(@"Making tiles");
	
	//make tile array
	int width = columns*(roomSize+1)+1;
	int height = rows*(roomSize+1)+1;
	self.tiles = [NSMutableArray new];
	for (int y = 0; y < height; y++)
	{
		NSMutableArray *row = [NSMutableArray new];
		for (int x = 0; x < width; x++)
			[row addObject:[[Tile alloc] initWithType:@"wall"]];
		[self.tiles addObject:row];
	}
	
	//place the player in the center of the start room
	int pX = (roomSize+1)*(columns / 2) + (roomSize / 2) + 1;
	int pY = (roomSize+1)*(rows - 1) + (roomSize / 2) + 1;
	Creature *player = [[Creature alloc] initWithX:pX andY:pY onMap:self];
	self.player = player;
	((Tile *)self.tiles[pY][pX]).inhabitant = player;
	[self.creatures addObject:player];
	
	//TODO: temporary enemy
	Creature *enemy = [[Creature alloc] initWithX:pX andY:pY-1 onMap:self ofEnemyType:@"temporary man"];
	((Tile *)self.tiles[pY-1][pX]).inhabitant = enemy;
	[self.creatures addObject:enemy];
	
	//translate rooms into tiles
	for (int y = 0; y < rows; y++)
		for (int x = 0; x < columns; x++)
		{
			GeneratorRoom *room = rooms[y][x];
			if (room.accessable) //don't draw inaccessable rooms
			{
				//draw the room
				int xS = 0;
				int yS = 0;
				if (room.upDoor == GeneratorRoomExitNoDoor)
					yS -= 1;
				if (room.leftDoor == GeneratorRoomExitNoDoor)
					xS -= 1;
				for (int y2 = yS; y2 < roomSize; y2++)
					for (int x2 = xS; x2 < roomSize; x2++)
					{
						int y3 = y2 + y * (roomSize + 1) + 1;
						int x3 = x2 + x * (roomSize + 1) + 1;
						((Tile *)self.tiles[y3][x3]).type = @"floor";
					}
				
				//place doors
				[self placeDoorOfType:room.upDoor atX:x*(roomSize+1)+1+(roomSize/2) andY:y*(roomSize+1)];
				[self placeDoorOfType:room.leftDoor atX:x*(roomSize+1) andY:y*(roomSize+1)+1+(roomSize/2)];
				
				//TODO: place enemies, treasure, etc
			}
		}
	
	//TODO: replace big parts of the map with cellular caves
	//where cellular cave floor is placed, it overwrites doors and walls
	//it overwrites room floor with a (VARIABLE)% chance, otherwise it turns room floor into room floor rubble
	//cave walls overwrite room walls too
	//there should be a "masking" layer to determine where overwriting happens
	//this should probably have some kinds of map generator variables too
}

-(NSArray *)pathExplore:(NSArray *)path aroundRooms:(NSArray *)rooms toExit:(GeneratorRoom *)exit intoPaths:(NSMutableArray *)paths withDesiredLength:(int)length
{
	//what is the room the path is on right now?
	GeneratorRoom *room = path.lastObject;
	
	//find the rooms that you can travel to from that room
	NSMutableArray *surroundingRooms = [NSMutableArray new];
	
	if (room.leftDoor != GeneratorRoomExitWall)
		[surroundingRooms addObject:rooms[room.y][room.x-1]];
	if (room.rightDoor != GeneratorRoomExitWall)
		[surroundingRooms addObject:rooms[room.y][room.x+1]];
	if (room.upDoor != GeneratorRoomExitWall)
		[surroundingRooms addObject:rooms[room.y-1][room.x]];
	if (room.downDoor != GeneratorRoomExitWall)
		[surroundingRooms addObject:rooms[room.y+1][room.x]];
	
	//for each room, if you haven't visited it, branch down that path
	//but access them in a random order
	int orderAdd = arc4random_uniform(surroundingRooms.count);
	for (int i = 0; i < surroundingRooms.count; i++)
	{
		GeneratorRoom *nextRoom = surroundingRooms[(i + orderAdd) % surroundingRooms.count];
		if (![path containsObject:nextRoom])
		{
			NSArray *newPath = [path arrayByAddingObject:nextRoom];
			
			if (nextRoom == exit)
			{
				//it's the end!
				if (newPath.count == length)
				{
					//it's the correct length! end immediately
					return newPath;
				}
				
				//add the path to the array
				[paths addObject:newPath];
			}
			else
			{
				//keep going down
				NSArray *result = [self pathExplore:newPath aroundRooms:rooms toExit:exit intoPaths:paths withDesiredLength:length];
				if (result != nil)
					return result; //just end instantly
			}
		}
	}
	return nil;
}

-(void)placeDoorOfType:(GeneratorRoomExit)type atX:(int)x andY:(int)y
{
	switch(type)
	{
		case GeneratorRoomExitPathDoor:
		case GeneratorRoomExitDoor:
			((Tile *)self.tiles[y][x]).type = @"floor"; //TODO: normal door (actually, floor might be ok for this? I dunno)
			break;
		case GeneratorRoomExitLockedDoor:
			((Tile *)self.tiles[y][x]).type = @"floor"; //TODO: locked door
			break;
		default:
			return;
	}
}

@end