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
#import "Creature.h"
#import "Constants.h"

@interface GameViewController () <MapViewDelegate, MapDelegate>

@property (weak, nonatomic) IBOutlet MapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *creatureView;
@property (weak, nonatomic) IBOutlet UIView *uiView;

@property (weak, nonatomic) IBOutlet UIView *mainPanel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainPanelCord;

@property (weak, nonatomic) IBOutlet UIView *attackSelectPanel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attackSelectPanelCord;

@property (weak, nonatomic) IBOutlet UIView *attackConfirmPanel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attackConfirmPanelCord;


@property (strong, nonatomic) Map* map;
@property (strong, nonatomic) NSMutableArray *creatureViews;
@property BOOL animating;
@property BOOL uiAnimating;
@property (weak, nonatomic) NSLayoutConstraint *activePanelCord;

@end

@implementation GameViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.activePanelCord = nil;
	self.animating = false;
	self.uiAnimating = false;
	
	self.map = [Map new];
	self.map.delegate = self;
	
	self.mapView.delegate = self;
	[self.mapView initializeMapAtX:self.map.player.x - GAMEPLAY_SCREEN_WIDTH * 0.5f + 0.5f andY:self.map.player.y - GAMEPLAY_SCREEN_HEIGHT * 0.5f + 0.5f];
	
	[self.map update];
	
	UITapGestureRecognizer *tappy = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
	[self.creatureView addGestureRecognizer:tappy];
	
	//make the creature views
	self.creatureViews = [NSMutableArray new];
	for (Creature *cr in self.map.creatures)
	{
		//make creature views
		float x = cr.x * GAMEPLAY_TILE_SIZE + self.mapView.xOffset;
		float y = cr.y * GAMEPLAY_TILE_SIZE + self.mapView.yOffset;
		UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x, y, GAMEPLAY_TILE_SIZE, GAMEPLAY_TILE_SIZE)];
		[self.creatureView addSubview:view];
		[self.creatureViews addObject:view];
		
		//add creature view sprites
		//TODO: add (including armor parts)
		view.backgroundColor = [UIColor redColor];
	}
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	//swing in the main UI
	[self switchToPanel:self.mainPanelCord];
}

//TODO: make sure that all panel buttons that do something check animating and uiAnimating
//and all panel buttons that just switch panels check uiAnimating

-(void)switchToPanel:(NSLayoutConstraint *)panelCord
{
	if (self.uiAnimating)
		return;
	self.uiAnimating = true;
	
	//TODO: there should be a duration constant
	
	panelCord.constant = -self.view.frame.size.width;
	[self.uiView layoutIfNeeded];
	
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:0.75f animations:
	^()
	{
		if (weakSelf.activePanelCord != nil)
			weakSelf.activePanelCord.constant = weakSelf.view.frame.size.width;
		panelCord.constant = 0;
		[weakSelf.uiView layoutIfNeeded];
	} completion:
	^(BOOL finished)
	{
		weakSelf.uiAnimating = false;
		weakSelf.activePanelCord = panelCord;
	}];
}

-(void)tapGesture:(UITapGestureRecognizer *)sender
{
	if (self.animating || self.uiAnimating)
		return;
	
	CGPoint touchPoint = [sender locationInView:self.mapView];
	int x = ((int)floorf(touchPoint.x) - self.mapView.xOffset) / GAMEPLAY_TILE_SIZE;
	int y = ((int)floorf(touchPoint.y) - self.mapView.yOffset) / GAMEPLAY_TILE_SIZE;

	NSLog(@"touched (%i %i), player is at (%i %i)", x, y, self.map.player.x, self.map.player.y);
	
	//move
	Creature *player = self.map.player;
	if (x != player.x || y != player.y)
	{
		int xDis = ABS(player.x - x);
		int yDis = ABS(player.y - y);
		BOOL moved = NO;
		if (xDis >= yDis)
		{
			if (player.x > x)
				moved = [self.map moveWithX:-1 andY:0];
			else
				moved = [self.map moveWithX:1 andY:0];
		}
		if (xDis <= yDis && !moved)
		{
			if (player.y > y)
				[self.map moveWithX:0 andY:-1];
			else
				[self.map moveWithX:0 andY:1];
		}
	}
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

-(int)mapWidth
{
	return self.map.width;
}
-(int)mapHeight
{
	return self.map.height;
}

#pragma mark: map delegate

-(void)moveCreature:(Creature *)creature withBlock:(void (^)(void))block
{
	if (creature == self.map.player)
		[self.mapView setPositionWithX:creature.x - GAMEPLAY_SCREEN_WIDTH * 0.5f + 0.5f andY:creature.y - GAMEPLAY_SCREEN_HEIGHT * 0.5f + 0.5f];
	
	__weak typeof(self) weakSelf = self;
	self.animating = true;
	[UIView animateWithDuration:GAMEPLAY_MOVE_TIME animations:
	^()
	{
		//move everything, not just the one guy
		for (int i = 0; i < weakSelf.creatureViews.count; i++)
		{
			Creature *cr = weakSelf.map.creatures[i];
			UIView *view = weakSelf.creatureViews[i];
			float x = cr.x * GAMEPLAY_TILE_SIZE + weakSelf.mapView.xOffset;
			float y = cr.y * GAMEPLAY_TILE_SIZE + weakSelf.mapView.yOffset;
			view.frame = CGRectMake(x, y, GAMEPLAY_TILE_SIZE, GAMEPLAY_TILE_SIZE);
		}
		
	} completion:
	^(BOOL finished)
	{
		//recalculate hidden
		for (int i = 0; i < weakSelf.creatureViews.count; i++)
		{
			Creature *cr = weakSelf.map.creatures[i];
			UIView *view = weakSelf.creatureViews[i];
			view.hidden = !((Tile *)weakSelf.map.tiles[cr.y][cr.x]).visible || !([self.mapView isPointOnscreenWithX:cr.x andY:cr.y]);
		}
		
		//the action is over
		weakSelf.animating = false;
		block();
	}];
}

@end
