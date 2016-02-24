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

@property float x;
@property float y;

-(int)xTranslate:(int)x;
-(int)yTranslate:(int)y;

@property (strong, nonatomic) NSMutableDictionary *tileDict;

@end


@implementation MapView

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


-(void)initializeMapAtX:(float)x andY:(float)y
{
	self.x = x;
	self.y = y;
	[self boundCamera];
	
	self.tileDict = [NSMutableDictionary new];
	[self generateTilesAroundX:self.x andY:self.y];
}

-(void)generateTilesAroundX:(float)xStart andY:(float)yStart
{
	for (int x = (int)floorf(xStart) - 1; x <= (int)ceilf(xStart) + GAMEPLAY_SCREEN_WIDTH; x++)
		for (int y = (int)floorf(yStart) - 1; y <= (int)ceilf(yStart) + GAMEPLAY_SCREEN_HEIGHT; y++)
			[self makeTileAtX:x andY:y];
}

-(void)boundCamera
{
	self.x = MAX(MIN(self.x, self.delegate.mapWidth - GAMEPLAY_SCREEN_WIDTH), 0);
	self.y = MAX(MIN(self.y, self.delegate.mapHeight - GAMEPLAY_SCREEN_HEIGHT), 0);
}

-(void)remake
{
	NSLog(@"Remaking map view");
	
	//clear tiles
	for (UIView *view in self.tileDict.allValues)
		[view removeFromSuperview];
	[self.tileDict removeAllObjects];
	
	//generate new tiles
	[self generateTilesAroundX:self.x andY:self.y];
}

-(void)setPositionWithX:(float)x andY:(float)y withAnimBlock:(void (^)(void))animBlock andCompleteBlock:(void (^)(void))completeBlock
{
	NSLog(@"Moving map to %f %f", x, y);
	
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
		animBlock();
		
		//shift all tiles over
		for (NSNumber *index in weakSelf.tileDict.allKeys)
		{
			UIView *tileView = weakSelf.tileDict[index];
			int x = index.intValue % INNER_YMULT;
			int y = index.intValue / INNER_YMULT;
//			tileView.frame = CGRectMake([weakSelf xTranslate:x], [weakSelf yTranslate:y], GAMEPLAY_TILE_SIZE, GAMEPLAY_TILE_SIZE);
			tileView.center = CGPointMake([weakSelf xTranslate:x] + GAMEPLAY_TILE_SIZE / 2, [weakSelf yTranslate:y] + GAMEPLAY_TILE_SIZE / 2);
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
		
		completeBlock();
	}];
}

-(BOOL)isPointOnscreenWithX:(int)x andY:(int)y
{
	return x >= (int)floorf(self.x) && y >= (int)floorf(self.y) &&
			x <= (int)ceilf(self.x) + GAMEPLAY_SCREEN_WIDTH && y <= (int)ceilf(self.y) + GAMEPLAY_SCREEN_HEIGHT;
}

@end
