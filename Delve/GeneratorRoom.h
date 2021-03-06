//
//  GeneratorRoom.h
//  Delve
//
//  Created by Theodore Abshire on 2/23/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface GeneratorRoom : NSObject

-(id)initWithSize:(int)size atX:(int)x andY:(int)y;

@property int x;
@property int y;
@property int size;
@property int layer;

-(int)xCorner;
-(int)yCorner;

@property (weak, nonatomic) GeneratorRoom *leftRoom;
@property (weak, nonatomic) GeneratorRoom *upRoom;
@property (weak, nonatomic) GeneratorRoom *rightRoom;
@property (weak, nonatomic) GeneratorRoom *downRoom;

@property BOOL startRoom;
@property BOOL accessable;
@property BOOL encounter;
@property TreasureClass treasure;
@property BOOL lockedOnly;

@property (nonatomic) GeneratorRoomExit leftDoor;
@property (nonatomic) GeneratorRoomExit upDoor;
@property (nonatomic) GeneratorRoomExit rightDoor;
@property (nonatomic) GeneratorRoomExit downDoor;

-(BOOL)canAddNoDoor;
-(BOOL)isPathRoom;
-(BOOL)validEncounterRoom;

@end