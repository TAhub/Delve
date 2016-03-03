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
#import "Item.h"

@interface Map()

@property int personOn;

@end

@implementation Map

-(id)initWithMap:(Map *)map
{
	if (self = [super init])
	{
		_creatures = [NSMutableArray new];
		_inventory = [NSMutableArray new];
		[self mapGenerateWithMap:map];
		
		//start right before the player's turn
		_personOn = (int)self.creatures.count - 1;
		
		[self recalculateVisibility];
		
		//TODO: these are temporary start items
		[self addItem:[[Item alloc] initWithName:@"bread" andType:ItemTypeInventory]];
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

-(void)addItem:(Item *)item
{
	//unload crafts
	self.preloadedCrafts = nil;
	
	BOOL stacked = false;
	for (Item *eItem in self.inventory)
		if ([item.name isEqualToString:eItem.name] && item.type == eItem.type)
		{
			eItem.number += item.number;
			stacked = true;
			break;
		}
	if (!stacked) //otherwise add it to the end of the inventory
		[self.inventory addObject:item];
}

-(BOOL)yourTurn
{
	return self.creatures[self.personOn] == self.player;
}

-(BOOL)canPickUp
{
	return ((Tile *)self.tiles[self.player.y][self.player.x]).treasureType != TreasureTypeNone;
}

-(BOOL)canCraft
{
	Tile *tile = self.tiles[self.player.y][self.player.x];
	if (tile.treasureType != TreasureTypeNone)
		return false;
	
	if (self.preloadedCrafts == nil)
		self.preloadedCrafts = self.player.recipies;
	
	//does the player have any crafting recipies they can pay for AND use the item of?
	return self.preloadedCrafts.count > 0;
}

-(BOOL)canPayForRecipie:(NSString *)recipie
{
	return [self payForRecipie:recipie part:@"a" doPay:false] && [self payForRecipie:recipie part:@"b" doPay:false];
}
-(BOOL)payForRecipie:(NSString *)recipie part:(NSString *)part doPay:(BOOL)pay
{
	if (!loadValueBool(@"Recipies", recipie, [NSString stringWithFormat:@"ingredient %@", part]))
		return true;
	NSString *material = loadValueString(@"Recipies", recipie, [NSString stringWithFormat:@"ingredient %@", part]);
	int materialAmount = loadValueNumber(@"Recipies", recipie, [NSString stringWithFormat:@"ingredient %@ amount", part]).intValue;
	
	for (Item *item in self.inventory)
	{
		if ([item.name isEqualToString:material] && item.number >= materialAmount)
		{
			if (pay)
			{
				item.number -= materialAmount;
				if (item.number == 0)
					[self.inventory removeObject:item];
			}
			
			return true;
		}
	}
	return false;
}
-(void)payForRecipie:(NSString *)recipie
{
	[self payForRecipie:recipie part:@"a" doPay:true];
	[self payForRecipie:recipie part:@"b" doPay:true];
}
-(Item *)makeItemFromRecipie:(NSString *)recipie
{
	NSString *name = loadValueString(@"Recipies", recipie, @"result");
	NSString *type = loadValueString(@"Recipies", recipie, @"result type");
	Item *it;
	if ([type isEqualToString:@"armor"])
		it = [[Item alloc] initWithName:name andType:ItemTypeArmor];
	else if ([type isEqualToString:@"implement"])
		it = [[Item alloc] initWithName:name andType:ItemTypeImplement];
	else
		it = [[Item alloc] initWithName:name andType:ItemTypeInventory];
	it.number = loadValueNumber(@"Recipies", recipie, @"result amount").intValue;
	return it;
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
		[self.delegate moveCreature:person fromX:person.x-x fromY:person.y-y withBlock:
		^()
		{
			if (person.good && true) //TODO: if you walked onto a stair tile
			{
				weakSelf.personOn = weakSelf.creatures.count + 5; //to make sure it's not the player's turn
				[weakSelf.delegate goToNextMap];
			}
			else
				[weakSelf update];
		}];
		return YES;
	}
	return NO;
}

-(void)recalculateVisibility
{
	int yS = MAX(self.player.y - GAMEPLAY_SCREEN_HEIGHT, 0);
	int yE = MIN(self.player.y + GAMEPLAY_SCREEN_HEIGHT, self.height - 1);
	int xS = MAX(self.player.x - GAMEPLAY_SCREEN_WIDTH, 0);
	int xE = MIN(self.player.x + GAMEPLAY_SCREEN_WIDTH, self.width - 1);
	for (int y = yS; y <= yE; y++)
		for (int x = xS; x <= xE; x++)
		{
			Tile *tile = self.tiles[y][x];
			tile.lastVisible = tile.visible;
			tile.visible = NO;
		}
	
	//project sight-lines from the player
//	BOOL visibleChanged = false;
	for (int i = 0; i < GAMEPLAY_SIGHT_LINE_DENSITY; i++)
	{
		float angle = M_PI * 2 * i / GAMEPLAY_SIGHT_LINE_DENSITY;
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
//			{
				tile.discovered = YES;
//				visibleChanged = YES;
//			}
		}
	}
	
//	if (!visibleChanged)
//		for (int y = yS; y <= yE && !visibleChanged; y++)
//			for (int x = xS; x <= xE; x++)
//			{
//				Tile *tile = self.tiles[y][x];
//				if (tile.lastVisible != tile.visible)
//				{
//					visibleChanged = YES;
//					break;
//				}
//			}
//	
//	if (visibleChanged)
//		[self.delegate updateTiles];
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

-(void)mapGenerateWithMap:(Map *)map
{
	for (int try = 1;; try++)
	{
		if ([self mapGenerateInnerWithMap:(Map *)map])
		{
			NSLog(@"Map generation finished on try #%i, with %u enemies", try, self.creatures.count - 1);
			return;
		}
	}
}

-(BOOL)mapGenerateInnerWithMap:(Map *)map
{
	//TODO: get map generator stuff
	//from the previous map
	//IE make sure this is one floor further
	//and make sure it follows the progression
	//etc
	
	
	
	
	//first, get map generator variables
	//TODO: get these from data, based on the floor number
	
	//how big a room is
	int roomSize = 5;
	
	//the height of the map; most maps should be taller than they are wide, since the game is meant to run in profile
	int rows = 10;
	
	//the width of the map
	int columns = 6;
	
	//the chance to reject doors added to undiscovered rooms
	//100 would mean it refuses to add doors to rooms that aren't discovered
	int rejectUndiscoveredDoorsChance = 80;
	
	//this is how much a door's position can vary; set to 0 for evenly-placed doors, don't set over (roomSize / 2) or else Bad Things will happen
	int maxDoorOffset = 1;
	
	//how many rooms should be added per layer; low values might result in hitting the layer limit
	int doorsAtATime = 5;
	
	//the minimum number of rooms there should be
	int minNonOrphans = 20;
	
	//the maximum number of rooms there should be
	int maxNonOrphans = 35;
	
	//what percent chance there should be for rooms to have locked doors
	int lockedDoorChance = 50;
	
	//what percent chance there should be for rooms to combine into long rooms
	int noDoorChance = 25;
	
	//how long the "real" path to the end should be
	int desiredPathLength = 7;
	
	//how many treasures should be equipment
	int equipmentTreasures = 5;
	
	//how often there are "dead" rooms (no treaure, no encounter); should probably be an odd number
	int deadRoomFrequency = 5;
	
	//how many equipment items you are guaranteed to get in the starting room
	int startEquipmentTreasures = 4;
	
	//the ratio of treasures to encounters; set high for lots of treasure, low for lots of encounters
	//keep it within 0.85-1.15 or so for balance and performance reasons
	float treasuresPerEncounter = 0.95;
	
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
	
	for (int layer = 0;; layer += 1)
	{
		if (layer == GENERATOR_MAX_LINK_LAYERS)
		{
			//TODO: restarting is okay right now because I don't define any permanent variables before this point (tiles, etc)
			//in the future though, I might add some
			NSLog(@"--ERROR: hit max link layer! Restarting");
			return false;
		}
		
		NSLog(@"--Making connections");
		
		//add some random connections
		int i = 0;
		for (int j = 0; i < doorsAtATime; j++)
		{
			if (j == GENERATOR_MAX_CONNECTION_TRIES)
			{
				//TODO: restarting is okay right now because I don't define any permanent variables before this point (tiles, etc)
				//in the future though, I might add some
				NSLog(@"--ERROR: hit max connection tries! Restarting");
				return false;
			}
			
			int x = (int)arc4random_uniform(columns);
			int y = (int)arc4random_uniform(rows);
			GeneratorRoom *room = rooms[y][x];
			if (room.accessable || arc4random_uniform(100) >= rejectUndiscoveredDoorsChance)
			{
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
							room.layer = layer;
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
			if (accessableRooms > maxNonOrphans)
			{
				//TODO: restarting is okay right now because I don't define any permanent variables before this point (tiles, etc)
				//in the future though, I might add some
				NSLog(@"--ERROR: too many accessable rooms! Restarting");
				return false;
			}
			
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
	
	NSLog(@"Making tiles");
	
	//make tile array
	int width = columns*(roomSize+1)+1;
	int height = rows*(roomSize+1)+1;
	self.tiles = [NSMutableArray new];
	for (int y = 0; y < height; y++)
	{
		NSMutableArray *row = [NSMutableArray new];
		for (int x = 0; x < width; x++)
			[row addObject:[[Tile alloc] initWithType:@"wall red"]];
		[self.tiles addObject:row];
	}
	
	//place the player in the center of the start room
	int pX = (roomSize+1)*(columns / 2) + (roomSize / 2) + 1;
	int pY = (roomSize+1)*(rows - 1) + (roomSize / 2) + 1;
	Creature *player;
	if (map == nil) //TODO: there should ALWAYS be a premade player, from the character screen, but for now make one here
		player = [[Creature alloc] initWithX:pX andY:pY onMap:self];
	else
		player = map.player;
	player.x = pX;
	player.y = pY;
	player.map = self;
	self.player = player;
	((Tile *)self.tiles[pY][pX]).inhabitant = player;
	[self.creatures addObject:player];
	
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
						((Tile *)self.tiles[y3][x3]).type = @"floor red";
					}
				
				//place doors
				[self placeDoorOfType:room.upDoor atX:x*(roomSize+1)+1+(roomSize/2) + (maxDoorOffset == 0 ? 0 : (arc4random_uniform(maxDoorOffset * 2 + 1) - maxDoorOffset)) andY:y*(roomSize+1)];
				[self placeDoorOfType:room.leftDoor atX:x*(roomSize+1) andY:y*(roomSize+1)+1+(roomSize/2) + (maxDoorOffset == 0 ? 0 : (arc4random_uniform(maxDoorOffset * 2 + 1) - maxDoorOffset))];
				
				//TODO: place enemies, treasure, etc
			}
		}
	
	//TODO: replace big parts of the map with cellular caves
	//where cellular cave floor is placed, it overwrites doors and walls
	//it overwrites room floor with a (VARIABLE)% chance, otherwise it turns room floor into room floor rubble
	//cave walls overwrite room walls too
	//there should be a "masking" layer to determine where overwriting happens
	//this should probably have some kinds of map generator variables too
	
	//TODO: locked-only rooms should never be breached by caves, paint those rooms (and their walls!) out of the cellular mask
	
	//TODO: identify rooms that were at least 50% uncovered by the cellular cave generation and mixing
	//those rooms should be marked as accessable but keep the -1 layer, so they can have stuff placed in them
 
	NSLog(@"Finding treasure and encounter locations");
	
	//add encounters and treasures to rooms
	int numEncounters = 0;
	int numTreasures = 0;
	for (NSArray *row in rooms)
		for (GeneratorRoom *room in row)
		{
			BOOL placeTreasure = false;
			BOOL placeEncounter = false;
			if ((room.x != columns / 2 || (room.y != rows - 1 && room.y != 0)) && room.accessable) //never place anything in the start room, the exit, or a wall
			{
				if (room.layer == -1)
				{
					//it's a cave-only room!
					if (arc4random_uniform(2) == 0)
						placeTreasure = YES;
					else
						placeEncounter = YES;
					
				}
				else if (room.layer % deadRoomFrequency == 0)
				{
					//nothing goes here
					//this is because I want some dead rooms
				}
				else if (room.layer % 2 == 0)
					placeEncounter = YES;
				else
					placeTreasure = YES;
			}
			
			if (placeEncounter)
			{
				room.encounter = YES;
				numEncounters += 1;
			}
			if (placeTreasure)
			{
				room.treasure = YES;
				numTreasures += 1;
			}
		}
	
	NSLog(@"Balancing treasure / encounter ratio");
	
	//balance up the treasure/encounter ratio by adding one to rooms containing the other
	int desiredTreasures = floorf(numEncounters * treasuresPerEncounter);
	NSLog(@"--Need %i more treasures", MAX(desiredTreasures - numTreasures, 0));
	for (int i = 0; i < GENERATOR_MAX_BALANCE_TRIES && numTreasures < desiredTreasures; i++)
	{
		int randomX = (int)arc4random_uniform((u_int32_t)columns);
		int randomY = (int)arc4random_uniform((u_int32_t)rows);
		GeneratorRoom *randomRoom = rooms[randomY][randomX];
		if (randomRoom.encounter && !randomRoom.treasure)
		{
			randomRoom.treasure = true;
			numTreasures += 1;
		}
	}
	int desiredEncounters = floorf(numTreasures / treasuresPerEncounter);
	NSLog(@"--Need %i more encounters", MAX(desiredEncounters - numEncounters, 0));
	for (int i = 0; i < GENERATOR_MAX_BALANCE_TRIES && numEncounters < desiredEncounters; i++)
	{
		int randomX = (int)arc4random_uniform((u_int32_t)columns);
		int randomY = (int)arc4random_uniform((u_int32_t)rows);
		GeneratorRoom *randomRoom = rooms[randomY][randomX];
		if (randomRoom.treasure && !randomRoom.encounter)
		{
			randomRoom.encounter = true;
			numEncounters += 1;
		}
	}
	
	//turn some treasures into equipment treasures
	NSMutableArray *treasureTiles = [NSMutableArray new];
	for (NSArray *row in rooms)
		for (GeneratorRoom *room in row)
			if (room.treasure && !room.equipmentTreasure)
				[treasureTiles addObject:room];
	[self shuffleArray:treasureTiles];
	for (int i = 0; i < equipmentTreasures && i < treasureTiles.count; i++)
		((GeneratorRoom *)treasureTiles[i]).equipmentTreasure = true;
	
	//the exit always has an encounter
	((GeneratorRoom *)rooms[columns/2][0]).encounter = true;
	
	//place treasures
	//these try to go in the center of their respecive rooms
	for (NSArray *row in rooms)
		for (GeneratorRoom *room in row)
		{
			//if at all possible, go to the center of the room
			int xC = room.x * (roomSize + 1) + 1 + (roomSize / 2);
			int yC = room.y * (roomSize + 1) + 1 + (roomSize / 2);
			Tile *centerTile = self.tiles[yC][xC];
			if (centerTile.validPlacementSpot)
				[self placeTreasureOn:centerTile equipmentTreasure:room.equipmentTreasure isUnlocked:NO];
			else
			{
				//find a random spot in the tile to place a treasure
				for (int i = 0; i < GENERATOR_MAX_RANDOM_TREASURE_TRIES; i++)
				{
					int xR = room.x * (roomSize + 1) + 1 + arc4random_uniform(roomSize);
					int yR = room.y * (roomSize + 1) + 1 + arc4random_uniform(roomSize);
					Tile *randomTile = self.tiles[yR][xR];
					if (randomTile.validPlacementSpot)
					{
						[self placeTreasureOn:randomTile equipmentTreasure:room.equipmentTreasure isUnlocked:NO];
						break;
					}
				}
			}
		}
	
	//place unlocked equipment treasures in the start
	for (int i = 0; i < startEquipmentTreasures;)
	{
		GeneratorRoom *startRoom = rooms[rows-1][columns/2];
		int xR = startRoom.x * (roomSize + 1) + 1 + arc4random_uniform(roomSize);
		int yR = startRoom.y * (roomSize + 1) + 1 + arc4random_uniform(roomSize);
		Tile *randomTile = self.tiles[yR][xR];
		if (randomTile.validPlacementSpot)
		{
			[self placeTreasureOn:randomTile equipmentTreasure:true isUnlocked:true];
			i++;
		}
	}
	
	NSLog(@"Placing encounters");
	
	//place encounters
	//these go wherever there is space inside the confines of the room
	for (NSArray *row in rooms)
		for (GeneratorRoom *room in row)
			if (room.encounter)
			{
				NSLog(@"--Choosing encounter");
				//TODO: pick a real encounter from a list
				NSArray *encounter = [NSArray arrayWithObjects:@"ruin feeder runt", @"ruin feeder runt", nil];
				
				NSLog(@"--Finding open spaces");
				//find every open space for a person in the area
				NSMutableArray *openSpaces = [NSMutableArray new];
				for (int y = 0; y < roomSize; y++)
					for (int x = 0; x < roomSize; x++)
					{
						int xA = room.x * (roomSize + 1) + 1 + x;
						int yA = room.y * (roomSize + 1) + 1 + y;
						Tile *tile = self.tiles[yA][xA];
						if (tile.validPlacementSpot)
							[openSpaces addObject:@(xA+yA*self.width)];
					}
				[self shuffleArray:openSpaces];
				
				NSLog(@"--Placing in those %lu spaces", (unsigned long)openSpaces.count);
				for (int i = 0; i < openSpaces.count && i < encounter.count; i++)
				{
					NSString *type = encounter[i];
					NSNumber *position = openSpaces[i];
					int x = position.intValue % self.width;
					int y = position.intValue / self.width;
					Tile *tile = self.tiles[y][x];
					Creature *enemy = [[Creature alloc] initWithX:x andY:y onMap:self ofEnemyType:type];
					//TODO: this is temporarily disabled
					[self.creatures addObject:enemy];
					tile.inhabitant = enemy;
				}
			}
	
	//TODO: if I do any recutting, it should be here
	//I probably shouldn't though
	
	//TODO: place exit door tile
	
	return true;
}

-(void)placeTreasureOn:(Tile *)tile equipmentTreasure:(BOOL)equipment isUnlocked:(BOOL)unlocked
{
	//TODO: this should be a map variable rather than something found here
	int floor = 0;
	
	int listNum = 999;
	NSString *listPrefix;
	ItemType type;
	if (equipment)
	{
		if (unlocked)
			tile.treasureType = TreasureTypeChest;
		else
			tile.treasureType = TreasureTypeLocked;
		
		//pick if it's an implement or an armor
		if (arc4random_uniform(2) == 0)
		{
			type = ItemTypeImplement;
			listPrefix = @"implements";
			switch(floor)
			{
				case 0:
				case 1:
				case 2:
					listNum = 1; break;
				case 3:
				case 4:
				case 5:
					listNum = 2; break;
				case 6:
				case 7:
				case 8:
				case 9:
					listNum = 4; break;
			}
		}
		else
		{
			type = ItemTypeArmor;
			listPrefix = @"armors";
			switch(floor)
			{
				case 0:
				case 1:
				case 2:
					listNum = 1; break;
				case 3:
				case 4:
				case 5:
					listNum = 2; break;
				case 6:
				case 7:
				case 8:
					listNum = 3; break;
				case 9:
					listNum = 4; break;
			}
		}
	}
	else
	{
		tile.treasureType = TreasureTypeFree;
		type = ItemTypeInventory;
		listPrefix = @"drops";
		switch(floor)
		{
			case 0:
			case 1:
				listNum = 1; break;
			case 2:
			case 3:
				listNum = 2; break;
			case 4:
			case 5:
			case 6:
				listNum = 3; break;
			case 7:
			case 8:
			case 9:
				listNum = 4; break;
		}
	}
	
	//if this complains about trying to find a list called "drops 999" or whatever, that's because there must be a gap in the listNum picking
	NSArray *list = loadArrayEntry(@"Lists", [NSString stringWithFormat:@"%@ %i", listPrefix, listNum]);
	int pick = arc4random_uniform((u_int32_t)list.count);
	tile.treasure = [[Item alloc] initWithName:list[pick] andType:type];
	
	if ([tile.treasure.name isEqualToString:@"crystal"])
	{
		//increase the number an amount based on the map
		switch(floor)
		{
			case 0:
			case 1:
				tile.treasure.number *= 3; break;
			case 2:
			case 3:
				tile.treasure.number *= 4; break;
			case 4:
			case 5:
				tile.treasure.number *= 5; break;
			case 6:
			case 7:
			case 8:
			case 9:
				tile.treasure.number *= 6; break;
		}
	}
}

-(void)shuffleArray:(NSMutableArray *)array
{
	for (int i = 0; i < array.count; i++)
	{
		int rand = arc4random_uniform((u_int32_t)array.count);
		[array exchangeObjectAtIndex:rand withObjectAtIndex:0];
	}
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
	int orderAdd = arc4random_uniform((u_int32_t)surroundingRooms.count);
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
			((Tile *)self.tiles[y][x]).type = @"door floor red";
			break;
		case GeneratorRoomExitLockedDoor:
			((Tile *)self.tiles[y][x]).type = @"locked door red";
			break;
		default:
			return;
	}
}

@end