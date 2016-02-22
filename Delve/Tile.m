//
//  Tile.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "Tile.h"

@implementation Tile

-(id)initWithType:(NSString *)type
{
	if (self = [super init])
	{
		_type = type;
		_inhabitant = nil;
	}
	return self;
}

-(BOOL)solid
{
	return [self.type isEqualToString:@"wall"];
}

-(UIColor *) color
{
	return (self.solid ? [UIColor grayColor] : [UIColor whiteColor]);
}

@end