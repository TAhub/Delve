//
//  Tile.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Creature;

//TODO: DESIGN GOAL: this should contain NO info on graphics

@interface Tile : NSObject

-(id)initWithType:(NSString *)type;

@property (strong, nonatomic) NSString *type;
-(BOOL) solid;
@property (weak, nonatomic) Creature *inhabitant;

@end