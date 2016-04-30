//
//  GeneratorRoom.m
//  Delve
//
//  Created by Theodore Abshire on 2/23/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "GeneratorRoom.h"

@interface GeneratorRoom()

@property GeneratorRoomExit downDoorInner;
@property GeneratorRoomExit rightDoorInner;

@end

@implementation GeneratorRoom

-(int)xCorner
{
	return self.x * (self.size + 1) + 1;
}
-(int)yCorner
{
	return self.y * (self.size + 1) + 1;
}

-(id)initWithSize:(int)size atX:(int)x andY:(int)y;
{
	if (self = [super init])
	{
		_x = x;
		_y = y;
		_size = size;
		_leftRoom = nil;
		_upRoom = nil;
		_layer = -1;
		_downDoorInner = GeneratorRoomExitWall;
		_rightDoorInner = GeneratorRoomExitWall;
		_accessable = false;
		_treasure = TreasureClassNone;
		_encounter = false;
		_lockedOnly = true;
	}
	return self;
}

-(void)setUpRoom:(GeneratorRoom *)upRoom
{
	_upRoom = upRoom;
	upRoom.downRoom = self;
}

-(void)setLeftRoom:(GeneratorRoom *)leftRoom
{
	_leftRoom = leftRoom;
	leftRoom.rightRoom = self;
}

-(GeneratorRoomExit)upDoor
{
	if (self.upRoom == nil)
		return GeneratorRoomExitWall;
	return self.upRoom.downDoorInner;
}
-(void)setUpDoor:(GeneratorRoomExit)upDoor
{
	if (self.upRoom != nil)
		self.upRoom.downDoorInner = upDoor;
}


-(GeneratorRoomExit)leftDoor
{
	if (self.leftRoom == nil)
		return GeneratorRoomExitWall;
	return self.leftRoom.rightDoorInner;
}
-(void)setLeftDoor:(GeneratorRoomExit)leftDoor
{
	if (self.leftRoom != nil)
		self.leftRoom.rightDoorInner = leftDoor;
}

-(GeneratorRoomExit)downDoor
{
	return self.downDoorInner;
}
-(void)setDownDoor:(GeneratorRoomExit)downDoor
{
	self.downDoorInner = downDoor;
}

-(GeneratorRoomExit)rightDoor
{
	return self.rightDoorInner;
}
-(void)setRightDoor:(GeneratorRoomExit)rightDoor
{
	self.rightDoorInner = rightDoor;
}

-(BOOL)canAddNoDoor
{
	return self.leftDoor != GeneratorRoomExitNoDoor && self.rightDoor != GeneratorRoomExitNoDoor &&
			self.upDoor != GeneratorRoomExitNoDoor && self.downDoor != GeneratorRoomExitNoDoor;
}
-(BOOL)isPathRoom
{
	return self.leftDoor == GeneratorRoomExitPathDoor || self.rightDoor == GeneratorRoomExitPathDoor ||
			self.upDoor == GeneratorRoomExitPathDoor || self.downDoor == GeneratorRoomExitPathDoor;
}
-(BOOL)validEncounterRoom
{
	if (self.encounter)
		return false;
	for (int i = 0; i < 4; i++)
	{
		GeneratorRoomExit type = GeneratorRoomExitDoor;
		GeneratorRoom *room;
		switch(i)
		{
			case 0:
				type = self.upDoor;
				room = self.upRoom;
				break;
			case 1:
				type = self.downDoor;
				room = self.downRoom;
				break;
			case 2:
				type = self.leftDoor;
				room = self.leftRoom;
				break;
			case 3:
				type = self.rightDoor;
				room = self.rightRoom;
				break;
		}
		if (room != nil && (room.encounter || room.startRoom))
		{
			//if the adjacent room is a cave room or you have a direct path to it, it's not a valid room
			if (type != GeneratorRoomExitLockedDoor && type != GeneratorRoomExitWall)
				return false;
			if (room.layer == -1)
				return false;
		}
	}
	return true;
}


@end