//
//  Item.m
//  Delve
//
//  Created by Theodore Abshire on 2/28/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Item.h"

@implementation Item

-(id)initWithName:(NSString *)name andType:(ItemType)type
{
	if (self = [super init])
	{
		_name = name;
		_type = type;
		_number = 1;
	}
	return self;
}

@end