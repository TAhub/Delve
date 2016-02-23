//
//  MapView.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#define INNER_YMULT 99999

#import "MapView.h"
#import "Constants.h"

@interface MapView()

@property int x;
@property int y;

-(int)xTranslate:(int)x;
-(int)yTranslate:(int)y;

@property (strong, nonatomic) NSMutableDictionary *tileDict;

@end


@implementation MapView

-(int)xCorner
{
	return self.x;
}
-(int)yCorner
{
	return self.y;
}

-(int)xOffset
{
	return GAMEPLAY_TILE_SIZE * (0 - self.x);
}
-(int)yOffset
{
	return GAMEPLAY_TILE_SIZE * (0 - self.y);
}

-(int)xTranslate:(int)x
{
	return (x - self.x) * GAMEPLAY_TILE_SIZE;
}
-(int)yTranslate:(int)y
{
	return (y - self.y) * GAMEPLAY_TILE_SIZE;
}

-(UIView *)makeTileAtX:(int)x andY:(int)y
{
	//does it already exist?
	UIView *tileView = self.tileDict[@(x + y * INNER_YMULT)];
	if (tileView != nil)
		return tileView;
	
	tileView = [self.delegate viewAtTileWithX:x andY:y];
	
	if (tileView == nil)
		return nil;
	
	tileView.frame = CGRectMake([self xTranslate:x], [self yTranslate:y], GAMEPLAY_TILE_SIZE, GAMEPLAY_TILE_SIZE);
	
	[self addSubview:tileView];
	self.tileDict[@(x + y * INNER_YMULT)] = tileView;
	
	return tileView;
}


-(void)initializeMapAtX:(int)x andY:(int)y
{
	self.x = x;
	self.y = y;
	[self boundCamera];
	
	self.tileDict = [NSMutableDictionary new];
	[self generateTilesAroundX:self.x andY:self.y];
}

-(void)generateTilesAroundX:(int)x andY:(int)y
{
	int xStart = x;
	int yStart = y;
	
	for (int x = xStart - 1; x <= xStart + GAMEPLAY_SCREEN_WIDTH; x++)
		for (int y = yStart - 1; y <= yStart + GAMEPLAY_SCREEN_HEIGHT; y++)
			[self makeTileAtX:x andY:y];
}

-(void)boundCamera
{
	self.x = MAX(MIN(self.x, self.delegate.mapWidth - GAMEPLAY_SCREEN_WIDTH), 0);
	self.y = MAX(MIN(self.y, self.delegate.mapHeight - GAMEPLAY_SCREEN_HEIGHT), 0);
}

-(void)setPositionWithX:(int)x andY:(int)y
{
	NSLog(@"Moving map to %i %i", x, y);
	
	//add all tiles that are going to be visible after this position change
	[self generateTilesAroundX:self.x andY:self.y];
	
	self.x = x;
	self.y = y;
	[self boundCamera];
	
	//use animations to shift everything over
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:GAMEPLAY_MOVE_TIME animations:
	^()
	{
		//shift all tiles over
		for (NSNumber *index in weakSelf.tileDict.allKeys)
		{
			UIView *tileView = weakSelf.tileDict[index];
			int x = index.intValue % INNER_YMULT;
			int y = index.intValue / INNER_YMULT;
			tileView.frame = CGRectMake([weakSelf xTranslate:x], [weakSelf yTranslate:y], GAMEPLAY_TILE_SIZE, GAMEPLAY_TILE_SIZE);
		}
		
	} completion:
	^(BOOL finished)
	{
		//remove all tiles that are now offscreen after this position change
		for (NSNumber *index in weakSelf.tileDict.allKeys)
		{
			int x = index.intValue % INNER_YMULT;
			int y = index.intValue / INNER_YMULT;
			
			if (![weakSelf isPointOnscreenWithX:x andY:y])
			{
				[((UIView *) weakSelf.tileDict[index]) removeFromSuperview];
				weakSelf.tileDict[index] = nil;
			}
		}
	}];
}

-(BOOL)isPointOnscreenWithX:(int)x andY:(int)y
{
	return x >= self.x && y >= self.y &&
			x <= self.x + GAMEPLAY_SCREEN_WIDTH && y <= self.y + GAMEPLAY_SCREEN_HEIGHT;
}

@end
