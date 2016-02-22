//
//  MapView.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#define INNER_YMULT 999

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

-(int)xTranslate:(int)x
{
	return (x - self.x + (GAMEPLAY_SCREEN_WIDTH / 2)) * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2;
}
-(int)yTranslate:(int)y
{
	return (y - self.y + (GAMEPLAY_SCREEN_HEIGHT / 2)) * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2;
}

-(UIView *)makeTileAtX:(int)x andY:(int)y
{
	//does it already exist?
	UIView *tileView = self.tileDict[@(x + y * INNER_YMULT)];
	if (tileView != nil)
		return tileView;
	
	tileView = [self.delegate viewAtTileWithX:x andY:y];
	
	tileView.frame = CGRectMake([self xTranslate:x], [self yTranslate:y], GAMEPLAY_TILE_SIZE, GAMEPLAY_TILE_SIZE);
	[self addSubview:tileView];
	self.tileDict[@(x + y * INNER_YMULT)] = tileView;
	
	return tileView;
}


-(void)initializeMapAtX:(int)x andY:(int)y
{
	self.x = x;
	self.y = y;
	
	self.tileDict = [NSMutableDictionary new];
	[self makeTileAtX:x andY:y];
}

-(void)generateTilesAroundX:(int)x andY:(int)y
{
	int xStart = x - GAMEPLAY_SCREEN_WIDTH / 2;
	int yStart = y - GAMEPLAY_SCREEN_WIDTH / 2;
	for (int x = xStart; x < xStart + GAMEPLAY_SCREEN_WIDTH; x++)
		for (int y = yStart; y < yStart + GAMEPLAY_SCREEN_HEIGHT; y++)
			[self makeTileAtX:x andY:y];
}


-(void)setPositionWithX:(int)x andY:(int)y
{
	//add all tiles that are going to be visible after this position change
	[self makeTileAtX:x andY:y];
	
	//use animations to shift everything over
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:1.0f animations:
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
			if (x < weakSelf.x - GAMEPLAY_SCREEN_WIDTH / 2 || y < weakSelf.y - GAMEPLAY_SCREEN_HEIGHT ||
				x >= weakSelf.x + GAMEPLAY_SCREEN_WIDTH / 2 || y >= weakSelf.y + GAMEPLAY_SCREEN_HEIGHT)
			{
				[((UIView *) weakSelf.tileDict[index]) removeFromSuperview];
				weakSelf.tileDict[index] = nil;
			}
		}
	}];
}

@end
