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

-(int)healing
{
	if (loadValueBool(@"InventoryItems", self.name, @"healing"))
		return loadValueNumber(@"InventoryItems", self.name, @"healing").intValue;
	return 0;
}
-(BOOL)usable
{
	return (self.healing > 0);
}

@end