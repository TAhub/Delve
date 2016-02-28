//
//  Item.h
//  Delve
//
//  Created by Theodore Abshire on 2/28/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@interface Item : NSObject

-(id)initWithName:(NSString *)name andType:(ItemType)type;

@property (strong, nonatomic) NSString *name;
@property ItemType type;
@property int number;

@end