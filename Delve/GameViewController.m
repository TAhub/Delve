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
		
		[self regenerateCreatureSprite:cr];
	}
}

-(void)regenerateCreatureSprite:(Creature *)cr
{
	int number = [self.map.creatures indexOfObject:cr];
	UIView *view = self.creatureViews[number];
	[self regenerateCreatureSprite:cr atView:view];
}
-(void)regenerateCreatureSprite:(Creature *)cr atView:(UIView *)view
{
	for (UIView *subView in view.subviews)
		[subView removeFromSuperview];
	
	//TODO: get actual coloration
	NSArray *colorations = loadValueArray(@"Races", cr.race, @"colorations");
	NSDictionary *coloration = colorations[0];
	UIColor *skinColor = loadColorFromName((NSString *)coloration[@"skin"]);
	UIColor *hairColor = loadColorFromName((NSString *)coloration[@"hair"]);
	
	
	NSMutableArray *images = [NSMutableArray new];
	NSMutableArray *yAdds = [NSMutableArray new];
	
	[self drawArmorsOf:cr withLayer:0 inArray:images withYAdds:yAdds];
	
	NSString *bodySprite = [NSString stringWithFormat:@"%@_%@", loadValueString(@"Races", cr.race, @"sprite"), cr.gender ? @"f" : @"m"];
	[images addObject:colorImage([UIImage imageNamed:bodySprite], skinColor)];
	[yAdds addObject:@(0)];
	
	[self drawArmorsOf:cr withLayer:1 inArray:images withYAdds:yAdds];
	
	//TODO: get the real hair sprite
	NSString *hairSprite = [NSString stringWithFormat:@"%@_hair1_%@", loadValueString(@"Races", cr.race, @"sprite"), cr.gender ? @"f" : @"m"];
	[images addObject:colorImage([UIImage imageNamed:hairSprite], hairColor)];
	[yAdds addObject:@(0)];
	
	[self drawArmorsOf:cr withLayer:2 inArray:images withYAdds:yAdds];
	
	NSLog(@"image layers: %i", images.count);
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:mergeImages(images, CGPointMake(0.5f, 1.0f), yAdds)];
	imageView.frame = CGRectMake(GAMEPLAY_TILE_SIZE / 2 - imageView.frame.size.width / 2, GAMEPLAY_TILE_SIZE - imageView.frame.size.height, imageView.frame.size.width, imageView.frame.size.height);
	[view addSubview:imageView];
}

-(void)drawArmorsOf:(Creature *)cr withLayer:(int)layer inArray:(NSMutableArray *)spriteArray withYAdds:(NSMutableArray *)yAdds
{
	NSArray *raceYAdds = loadValueArray(@"Races", cr.race, @"armor slot y offsets");
	
	for (int i = 0; i < cr.armors.count; i++)
	{
		NSString *armor = cr.armors[i];
		if (armor.length > 0 && loadValueBool(@"Armors", armor, @"sprite"))
		{
			//lock to layer
			BOOL rightLayer = false;
			switch(layer)
			{
				case 0: //below layer
					rightLayer = loadValueBool(@"Armors", armor, @"sprite back");
					break;
				case 1: //below hair layer
					rightLayer = !loadValueBool(@"Armors", armor, @"sprite over hair");
					break;
				case 2: //over hair layer
					rightLayer = loadValueBool(@"Armors", armor, @"sprite over hair");
					break;
			}
			
			if (rightLayer)
			{
				int yAdd = ((NSNumber *)raceYAdds[i]).intValue;
				
				NSString *spriteName = loadValueString(@"Armors", armor, @"sprite");
				if (layer == 0)
					spriteName = [NSString stringWithFormat:@"%@_back", spriteName];
				if (loadValueBool(@"Armors", armor, @"sprite gender"))
					spriteName = [NSString stringWithFormat:@"%@_%@", spriteName, cr.gender ? @"f" : @"m"];
				if (cr.gender && loadValueBool(@"Armors", armor, @"female y add"))
					yAdd += loadValueNumber(@"Armors", armor, @"female y add").intValue;
				
				//draw armor sprite
				UIImage *sprite = [UIImage imageNamed:spriteName];
				UIImage *coloredSprite = colorImage(sprite, loadColorFromName(loadValueString(@"Armors", armor, @"color")));
				[spriteArray addObject:coloredSprite];
				[yAdds addObject:@(yAdd)];
			}
		}
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
