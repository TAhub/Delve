//
//  GameViewController.m
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "GameViewController.h"
#import "Map.h"
#import "Tile.h"
#import "MapView.h"

@interface GameViewController () <MapViewDelegate>

@property (strong, nonatomic) Map* map;
@property (weak, nonatomic) IBOutlet MapView *mapView;

@end

@implementation GameViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.map = [Map new];
	
	self.mapView.delegate = self;
	[self.mapView initializeMapAtX:self.map.width / 2 andY:self.map.height / 2];
	
	[self.map update];
}

#pragma mark: map view delegate

-(UIView *)viewAtTileWithX:(int)x andY:(int)y
{
	if (x < 0 || y < 0 || x >= self.map.width || y >= self.map.height)
		return nil;
	
	//get the tile
	Tile *tile = self.map.tiles[y][x];
	
	//make the tile view
	UIView *tileView = [UIView new];
	tileView.backgroundColor = tile.color;
	return tileView;
}

@end
