//
//  GameMapViewController.m
//  Delve
//
//  Created by Theodore Abshire on 4/26/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "GameMapViewController.h"
#import "Map.h"
#import "MapView.h"
#import "Creature.h"
#import "Tile.h"
#import "Item.h"
#import "CharacterServices.h"
#import "SoundPlayer.h"

@interface GameMapViewController () <MapViewDelegate>

@property (strong, nonatomic) NSMutableDictionary *preloadedTileImages;
@property (strong, nonatomic) NSMutableDictionary *preloadedGlowLayerImages;
@property (strong, nonatomic) NSMutableArray *creatureViews;

@end

@implementation GameMapViewController

-(void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	//set up the map view
	self.mapView.delegate = self;
	[self.mapView initializeMapAtX:self.map.player.x - GAMEPLAY_SCREEN_WIDTH * 0.5f + 0.5f andY:self.map.player.y - GAMEPLAY_SCREEN_HEIGHT * 0.5f + 0.5f];
	
	//play the appropriate music
	[self.map playFloorMusic];
	
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
	[self recalculateHidden];
}

#pragma mark loading

-(void)loadSave
{
	self.map = [[Map alloc] initFromSave];
	[self preloadTileImages];
}

-(void)loadMap:(Map *)map
{
	self.map = map;
	[self.map saveFirst];
	[self preloadTileImages];
}

-(void)loadGen:(Creature *)genPlayer
{
	self.map = [[Map alloc] initWithGen:genPlayer];
	[self.map saveFirst];
	[self preloadTileImages];
	
	
	//initialize player statistics
	NSMutableDictionary *killsPerRace = [NSMutableDictionary new];
	NSDictionary *races = loadEntries(@"Races");
	for (NSString *race in races.allKeys)
		killsPerRace[race] = @(0);
	[[NSUserDefaults standardUserDefaults] setObject:killsPerRace forKey:@"statistics kills"];
	[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"statistics steps"];
}

#pragma mark image loading

-(void)preloadTileImageFor:(Tile *)tile
{
	//get the floor number's default color
	UIColor *defColor = loadColorFromName(self.map.defaultColor);
	
	if (tile.type != nil && tile.spriteName != nil && self.preloadedTileImages[tile.type] == nil)
	{
		UIColor *color = tile.color;
		if (color == nil)
			color = defColor;
		UIImage *tileSprite = colorImage([UIImage imageNamed:tile.spriteName], color);
		self.preloadedTileImages[tile.type] = tileSprite;
		
		NSString *glowLayer = tile.glowLayerName;
		if (glowLayer != nil)
		{
			UIImage *glowImage = colorImage([UIImage imageNamed:glowLayer], tile.glowLayerColor);
			self.preloadedGlowLayerImages[tile.type] = glowImage;
		}
	}
}

-(void)preloadTileImages
{
	self.preloadedTileImages = [NSMutableDictionary new];
	self.preloadedGlowLayerImages = [NSMutableDictionary new];
	for (NSArray *row in self.map.tiles)
		for (Tile *tile in row)
			[self preloadTileImageFor:tile];
	
}

-(void)regenerateCreatureSprite:(Creature *)cr
{
	int number = (int)[self.map.creatures indexOfObject:cr];
	UIView *view = self.creatureViews[number];
	//	[self regenerateCreatureSprite:cr atView:view];
	makeCreatureSpriteInView(cr, view);
}

#pragma mark: map view delegate

-(void) glowFade:(UIView *)view withDuration:(float)duration atStart:(BOOL)start
{
	__weak typeof(self) weakSelf = self;
	
	if (start)
	{
		//start at a random position, with a random direction
		view.alpha = arc4random_uniform(100) * 0.01f;
		
		BOOL forward = arc4random_uniform(100) < 50;
		float distance = forward ? (1 - view.alpha) : view.alpha;
		
		[UIView animateWithDuration:duration * distance animations:
		^()
		{
			view.alpha = forward ? 1 : 0;
		} completion:
		^(BOOL complete)
		{
			if (forward) //it's at full alpha, so restart instantly
				[weakSelf glowFade:view withDuration:duration atStart:NO];
			else
			{
				//it's at 0 alpha, so fade in before restarting
				[UIView animateWithDuration:duration animations:
				^()
				{
					view.alpha = 1;
				} completion:
				^(BOOL complete)
				{
					[weakSelf glowFade:view withDuration:duration atStart:NO];
				}];
			}
		}];
		return;
	}
	
	if (view.superview == nil)
		return;
	
	[UIView animateWithDuration:duration animations:
	^()
	{
		view.alpha = 0;
	} completion:
	^(BOOL complete)
	{
		[UIView animateWithDuration:duration animations:
		^()
		{
			view.alpha = 1;
		} completion:
		^(BOOL complete)
		{
			[weakSelf glowFade:view withDuration:duration atStart:NO];
		}];
	}];
}

-(UIView *)viewAtTileWithX:(int)x andY:(int)y andOldView:(UIView *)oldView
{
	if (x < 0 || y < 0 || x >= self.map.width || y >= self.map.height)
		return nil;
	
	//get the tile
	Tile *tile = self.map.tiles[y][x];
	
	if (!tile.changed && oldView != nil && tile.visible == tile.lastVisible)
		return oldView;
	
	//you responded to the change, so set changed to false
	tile.changed = false;
	
	//just don't draw tiles that aren't visible
	UIView *tileView = nil;
	if (tile.visible || tile.discovered)
	{
		//make the tile view
		tileView = [UIView new];
		if (tile.spriteName != nil)
		{
			[self preloadTileImageFor:tile]; //preload that image if necessary
			
			//load a preloaded tile image
			UIImageView *tileSpriteView = [[UIImageView alloc] initWithImage:self.preloadedTileImages[tile.type]];
			[tileView addSubview:tileSpriteView];
		}
		else
			tileView.backgroundColor = tile.color;
		
		//make the glow layer view
		if (tile.glowLayerName != nil)
		{
			UIImage *image = self.preloadedGlowLayerImages[tile.type];
			if (image != nil)
			{
				UIImageView *glowView = [[UIImageView alloc] initWithImage:image];
				[tileView addSubview:glowView];
				[self glowFade:glowView withDuration:tile.glowDuration atStart:YES];
			}
		}
		
		//target color view
		UIColor *targetColor = nil;
		if (tile.targetLevel == TargetLevelInRange)
			targetColor = loadColorFromName(@"ui warning pale");
		else if (tile.targetLevel == TargetLevelTarget)
			targetColor = loadColorFromName(@"ui warning");
		if (targetColor != nil)
		{
			UIView *targetView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, GAMEPLAY_TILE_SIZE, GAMEPLAY_TILE_SIZE)];
			targetView.backgroundColor = targetColor;
			targetView.alpha = APPEARANCE_TARGETTILE_ALPHA;
			[tileView addSubview:targetView];
		}
		
		//discovered but invisible tiles should be transparent
		if (!tile.visible && targetColor == nil)
			tileView.alpha = APPEARANCE_TARGETTILE_ALPHA;
	}
	if (tile.treasureType != TreasureTypeNone)
	{
		NSString *treasureName = nil;
		UIColor *treasureColor = nil;
		switch (tile.treasureType)
		{
			case TreasureTypeBag:
				treasureName = @"pouch";
				treasureColor = loadColorFromName(@"leather");
				break;
			case TreasureTypeChest:
				treasureName = @"chest_open";
				treasureColor = loadColorFromName(@"relic");
				break;
			case TreasureTypeLocked:
				treasureName = @"chest";
				treasureColor = loadColorFromName(@"relic");
				break;
			case TreasureTypeFree:
				treasureName = loadValueString(@"InventoryItems", tile.treasure.name, @"sprite");
				treasureColor = loadColorFromName(loadValueString(@"InventoryItems", tile.treasure.name, @"color"));
				break;
			default: break;
		}
		UIImage *treasureSprite = colorImage([UIImage imageNamed:treasureName], treasureColor);
		
		UIImageView *treasureView = [[UIImageView alloc] initWithImage:treasureSprite];
		treasureView.center = CGPointMake(GAMEPLAY_TILE_SIZE / 2, GAMEPLAY_TILE_SIZE / 2);
		[tileView addSubview:treasureView];
	}
	if (tile.aoeTargeters.count > 0 && self.attackChosen == nil)
	{
		if (tileView == nil)
			tileView = [UIView new]; //make an empty container view
		
		//TODO: this image should be preloaded probably
		UIImage *warning = [UIImage imageNamed:@"ui_warning"];
		warning = colorImage(warning, loadColorFromName(@"ui warning"));
		
		UIImageView *warningView = [[UIImageView alloc] initWithImage:warning];
		warningView.center = CGPointMake(GAMEPLAY_TILE_SIZE / 2, GAMEPLAY_TILE_SIZE / 2);
		[tileView addSubview:warningView];
	}
	
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

#pragma mark move anim stuff

-(void)recalculateHidden
{
	for (int i = 0; i < self.creatureViews.count; i++)
	{
		Creature *cr = self.map.creatures[i];
		UIView *view = self.creatureViews[i];
		view.hidden = !((Tile *)self.map.tiles[cr.y][cr.x]).visible || !([self.mapView isPointOnscreenWithX:cr.x andY:cr.y]);
	}
}

-(void)moveCreatureAnim
{
	//move everything, not just the one guy
	for (int i = 0; i < self.creatureViews.count; i++)
	{
		Creature *cr = self.map.creatures[i];
		UIView *view = self.creatureViews[i];
		float x = (cr.x + 0.5) * GAMEPLAY_TILE_SIZE + self.mapView.xOffset;
		float y = (cr.y + 0.5) * GAMEPLAY_TILE_SIZE + self.mapView.yOffset;
		view.center = CGPointMake(x, y);
		//view.frame = CGRectMake(x, y, GAMEPLAY_TILE_SIZE, GAMEPLAY_TILE_SIZE);
	}
}

-(void)fadeScreenInTime:(float)time withBlock:(void (^)(void))block
{
	//fade the screen away
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:time animations:
	 ^()
	 {
		 weakSelf.view.backgroundColor = [UIColor blackColor];
		 for (int i = 0; i < weakSelf.creatureViews.count; i++)
		 {
			 UIView *view = weakSelf.creatureViews[i];
			 Creature *creature = weakSelf.map.creatures[i];
			 if (!creature.good)
				 view.alpha = 0;
		 }
		 weakSelf.mapView.alpha = 0;
		 
	 } completion:
	 ^(BOOL finished)
	 {
		 block();
	 }];
}

-(void)goToNextMap
{
	//	NSLog(@"Finished map with %i left on the countdown!", self.map.countdown);
	
	//do a fancy end-of-map animation
	self.animating = true;
	__weak typeof(self) weakSelf = self;
	[self fadeScreenInTime:0.6f withBlock:
	 ^()
	 {
		 int number = (int)[weakSelf.map.creatures indexOfObject:weakSelf.map.player];
		 UIView *view = weakSelf.creatureViews[number];
		 
		 [UIView animateWithDuration:0.4f animations:
		  ^()
		  {
			  //the player zooms away
			  view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y - weakSelf.view.frame.size.height, view.frame.size.width, view.frame.size.height);
			  
		  } completion:
		  ^(BOOL finished)
		  {
			  view.alpha = 0;
			  [weakSelf nextMapInner];
		  }];
	 }];
}

#pragma mark: map delegate

-(void)moveCreatureCompleteWithBlock:(void (^)(void))block
{
	//the action is over
	self.animating = false;
	[self recalculateHidden];
	block();
}

-(void)moveCreature:(Creature *)creature fromX:(int)x fromY:(int)y withBlock:(void (^)(void))block
{
	__weak typeof(self) weakSelf = self;
	self.animating = true;
	
	if (creature == self.map.player)
	{
		__block BOOL finishedFirst = true;
		
		//do some visibility recalculating on another thread
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^() {
			[weakSelf.map recalculateVisibility];
			dispatch_async(dispatch_get_main_queue(), ^() {
				if (finishedFirst)
					finishedFirst = false;
				else
				{
					[weakSelf updateTiles];
					[weakSelf moveCreatureCompleteWithBlock:block];
				}
			});
		});
		
		[self.mapView setPositionWithX:creature.x - GAMEPLAY_SCREEN_WIDTH * 0.5f + 0.5f andY:creature.y - GAMEPLAY_SCREEN_HEIGHT * 0.5f + 0.5f withAnimBlock:
		 ^()
		 {
			 [weakSelf moveCreatureAnim];
		 } andCompleteBlock:
		 ^()
		 {
			 if (finishedFirst)
				 finishedFirst = false;
			 else
			 {
				 [weakSelf updateTiles];
				 [weakSelf moveCreatureCompleteWithBlock:block];
			 }
		 }];
	}
	else
	{
		//invisible moves should be instant
		Tile *from = self.map.tiles[y][x];
		Tile *to = self.map.tiles[creature.y][creature.x];
		float time = GAMEPLAY_MOVE_TIME;
		if (!from.visible && !to.visible)
			time = 0.01f;
		
		[UIView animateWithDuration:time animations:
		 ^()
		 {
			 [weakSelf moveCreatureAnim];
		 } completion:
		 ^(BOOL finished)
		 {
			 [weakSelf moveCreatureCompleteWithBlock:block];
		 }];
	}
}

-(void)updateTiles
{
	[self.mapView remake];
}

-(void)updateCreature:(Creature *)cr
{
	[self regenerateCreatureSprite:cr];
}

-(void)shakeWithShakes:(int)shakes andBlock:(void (^)(void))block
{
	shakes -= 1;
	
	float xOff, yOff;
	if (shakes > 0)
	{
		float direction = arc4random_uniform(100) * 0.01f * 2 * M_PI;
		xOff = 4 * cos(direction);
		yOff = 4 * sin(direction);
	}
	else
	{
		xOff = 0;
		yOff = 0;
	}
	
	CGRect cFrame = self.creatureView.frame;
	CGRect mFrame = self.mapView.frame;
	
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:0.1f animations:
	 ^()
	 {
		 weakSelf.creatureView.frame = CGRectMake(cFrame.origin.x + xOff, cFrame.origin.y + yOff, cFrame.size.width, cFrame.size.height);
		 weakSelf.mapView.frame = CGRectMake(mFrame.origin.x + xOff, mFrame.origin.y + yOff, mFrame.size.width, mFrame.size.height);
	 } completion:
	 ^(BOOL finished)
	 {
		 weakSelf.creatureView.frame = cFrame;
		 weakSelf.mapView.frame = mFrame;
		 
		 if (shakes == 0)
			 block();
		 else
			 [weakSelf shakeWithShakes:shakes andBlock:block];
	 }];
}

-(void)nextMapInner
{
	if (self.map.floorNum == 9)
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"game phase"];
		
		//you won!
		NSString *title;
		NSMutableString *victoryMessage = [NSMutableString new];
		[victoryMessage appendString:@"As you exit the portal, you find yourself in the control room of the old Eol vessel."];
		
		//append an ending based on your race and actions
		NSDictionary *killsPerRace = [[NSUserDefaults standardUserDefaults] objectForKey:@"statistics kills"];
		NSArray *endingsArray = loadValueArray(@"Races", self.map.player.race, @"endings");
		for (NSString *ending in endingsArray)
		{
			BOOL valid = true;
			
			//check your kills in a specific race
			if (loadValueBool(@"Endings", ending, @"no kills of race"))
			{
				NSString *noKillsRace = loadValueString(@"Endings", ending, @"no kills of race");
				NSNumber *kills = killsPerRace[noKillsRace];
				if (kills.intValue > 0)
					valid = false;
			}
			
			//check to see if you have the right skills
			if (loadValueBool(@"Endings", ending, @"possess skill from list"))
			{
				BOOL has = false;
				NSArray *skillList = loadValueArray(@"Endings", ending, @"possess skill from list");
				for (NSString *skill in skillList)
					for (NSString *mySkill in self.map.player.skillTrees)
						if ([mySkill isEqualToString:skill])
						{
							has = true;
							break;
						}
				if (!has)
					valid = false;
			}
			
			//check your kills in various categories
			for (int i = 0; i < 3; i++)
			{
				NSString *deathCategory;
				switch(i)
				{
					case 0: deathCategory = @"animal"; break;
					case 1: deathCategory = @"person"; break;
					case 2: deathCategory = @"robot"; break;
				}
				if (loadValueBool(@"Endings", ending, [NSString stringWithFormat:@"no %@ kills", deathCategory]))
					for (NSString *race in killsPerRace.allKeys)
						if ([loadValueString(@"Races", race, @"death category") isEqualToString:deathCategory])
						{
							valid = false;
							break;
						}
			}
			
			if (valid)
			{
				[victoryMessage appendFormat:@"\n%@", [loadValueString(@"Endings", ending, @"text") stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]];
				title = loadValueString(@"Endings", ending, @"title");
				break;
			}
		}
		
		[victoryMessage appendFormat:@"\n%@", self.map.endStatistics];
		
		//register the score
		[self registerScore:title withSuccess:YES];
		
		//play victory music
		[[SoundPlayer sharedPlayer] playBGM:@"Feather Waltz.mp3"];
		
		self.defeatMessage = victoryMessage;
		[self performSegueWithIdentifier:@"defeat" sender:self];
	}
	else
		[self performSegueWithIdentifier:@"changeMap" sender:self];
}

-(void)defeat:(NSString *)message
{
	//null the save
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"game phase"];
	
	//do a fancy end-of-map animation
	self.animating = true;
	__weak typeof(self) weakSelf = self;
	[self fadeScreenInTime:2.5f withBlock:
	 ^()
	 {
		 //register the defeat
		 [self registerScore:[NSString stringWithFormat:@"Died on floor %i", self.map.floorNum + 1] withSuccess:YES];
		 
		 //play defeat music
		 [[SoundPlayer sharedPlayer] playBGM:@"Steel and Seething.mp3"];
		 
		 //go to the defeat screen
		 weakSelf.defeatMessage = message;
		 [weakSelf performSegueWithIdentifier:@"defeat" sender:weakSelf];
	 }];
}

-(void) registerScore:(NSString *)score withSuccess:(BOOL)success
{
	int floor = self.map.floorNum;
	if (success)
		floor += 1;
	
	//pull down the scores list and the score floors list
	NSMutableArray *scoreFloors = [[NSUserDefaults standardUserDefaults] objectForKey:@"score floors"];
	NSMutableArray *scores = [[NSUserDefaults standardUserDefaults] objectForKey:@"scores"];
	if (scoreFloors == nil)
	{
		//the scores weren't made, so initialize them
		scoreFloors = [NSMutableArray new];
		scores = [NSMutableArray new];
	}
	else
	{
		scoreFloors = [NSMutableArray arrayWithArray:scoreFloors];
		scores = [NSMutableArray arrayWithArray:scores];
	}
	
	//figure out where to insert the score
	int placePosition = -1;
	for (int i = 0; i < scores.count; i++)
	{
		NSNumber *sF = scoreFloors[i];
		if (sF.intValue == floor)
		{
			placePosition = i;
			break;
		}
	}
	if (placePosition == -1)
		placePosition = (int)scores.count;
	
	//insert at the right place
	[scoreFloors insertObject:@(floor) atIndex:placePosition];
	[scores insertObject:[NSString stringWithFormat:@"%@ %@: %@", self.map.player.gender ? @"F" : @"M", [self.map.player.race capitalizedString], score] atIndex:placePosition];
	
	//trim excess runs
	int maxScores = 30;
	while (scoreFloors.count > maxScores)
		[scoreFloors removeLastObject];
	while (scores.count > maxScores)
		[scoreFloors removeLastObject];
	
	//save the scores away
	[[NSUserDefaults standardUserDefaults] setObject:scoreFloors forKey:@"score floors"];
	[[NSUserDefaults standardUserDefaults] setObject:scores forKey:@"scores"];
}

@end