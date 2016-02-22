//
//  Map.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>

//TODO: DESIGN GOAL: this should contain NO info on graphics

@interface Map : NSObject

-(id)init;

@property (strong, nonatomic) NSMutableArray *tiles; //an array of arrays of tiles
@property (strong, nonatomic) NSMutableArray *creatures; //an array of creatures, for turn order

-(int)width;
-(int)height;

@end