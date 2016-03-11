//
//  Item.h
//  Delve
//
//  Created by Theodore Abshire on 2/28/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@class Creature;

@interface Item : NSObject

-(id)initWithName:(NSString *)name andType:(ItemType)type;

@property (strong, nonatomic) NSString *name;
@property ItemType type;
@property int number;

-(int)healing;
-(BOOL)usable;
-(NSString *)itemDescriptionWithCreature:(Creature *)creature;

@end