//
//  Tile.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Creature;

//TODO: DESIGN GOAL: this should contain NO info on graphics

@interface Tile : NSObject

-(id)initWithType:(NSString *)type;

@property (strong, nonatomic) NSString *type;
-(BOOL) solid;
-(UIColor *) color;
@property (weak, nonatomic) Creature *inhabitant;
@property BOOL visible;
@property BOOL lastVisible;
@property BOOL discovered;
@property (strong, nonatomic) NSMutableSet *aoeTargeters;

@end