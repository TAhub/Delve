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
@property (weak, nonatomic) IBOutlet UIView *statView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainPanelCord;

@property (weak, nonatomic) IBOutlet UIView *attackSelectPanel;
@property (weak, nonatomic) IBOutlet UIButton *attackB1;
@property (weak, nonatomic) IBOutlet UIButton *attackB2;
@property (weak, nonatomic) IBOutlet UIButton *attackB3;
@property (weak, nonatomic) IBOutlet UIButton *attackB4;
@property (weak, nonatomic) IBOutlet UIButton *attackB5;
@property (weak, nonatomic) IBOutlet UIButton *attackB6;
@property (weak, nonatomic) IBOutlet UIButton *attackNext;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attackSelectPanelCord;

@property (weak, nonatomic) IBOutlet UIView *attackConfirmPanel;
@property (weak, nonatomic) IBOutlet UILabel *attackConfirmLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attackConfirmPanelCord;

@property (weak, nonatomic) IBOutlet UIView *attackNamePanel;
@property (weak, nonatomic) IBOutlet UILabel *attackNameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attackNamePanelCord;



@property (strong, nonatomic) Map* map;
@property (strong, nonatomic) NSMutableArray *creatureViews;
@property BOOL animating;
@property BOOL uiAnimating;
@property (weak, nonatomic) NSLayoutConstraint *activePanelCord;
@property int attackPage;
@property (strong, nonatomic) NSString *attackChosen;
@property (weak, nonatomic) UIView *aoeIndicatorView;

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
	
	UITapGestureRecognizer *tappy = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
	[self.creatureView addGestureRecognizer:tappy];
	
	//format panels
	[self formatPanel:self.mainPanel];
	[self formatPanel:self.attackNamePanel];
	[self formatPanel:self.attackConfirmPanel];
	[self formatPanel:self.attackSelectPanel];
}

-(void)formatPanel:(UIView *)panel
{
//	panel.layer.borderWidth = .0;
//	panel.layer.borderColor = panel.backgroundColor.CGColor;
	panel.layer.cornerRadius = 5.0;
}

-(void)regenerateCreatureSprite:(Creature *)cr
{
	int number = (int)[self.map.creatures indexOfObject:cr];
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

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.map recalculateVisibility];
	[self.map update];
	
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
	
	//set up UI panels
	[self reloadPanels];
	
	//TODO: remember to draw the mask of tiles that are in-range when picking a target for an attack
}

-(void)reloadPanels
{
	//reload the info panel
	for (UIView *subView in self.statView.subviews)
		[subView removeFromSuperview];
	UILabel *statLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	statLabel.text = [NSString stringWithFormat:@"H%i/%i  D%i/%i  B%i/%i  K%i/%i", self.map.player.health, self.map.player.maxHealth, self.map.player.dodges, self.map.player.maxDodges, self.map.player.blocks, self.map.player.maxBlocks, self.map.player.hacks, self.map.player.maxHacks];
	statLabel.textColor = loadColorFromName(@"ui text");
	//TODO: display blocks, dodges, and hacks as rows of icons
	[statLabel sizeToFit];
	[self.statView addSubview:statLabel];
	
	UILabel *statLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(0, statLabel.frame.size.height, 0, 0)];
	statLabel2.text = [NSString stringWithFormat:@"%i%% dam", self.map.player.damageBonus];
	//TODO: display resistances as rows of icons
	[statLabel2 sizeToFit];
	statLabel2.textColor = loadColorFromName(@"ui text");
	[self.statView addSubview:statLabel2];
	
	
	//set up attacks panel with a list of attacks (greyed out buttons for attacks you can't use)
	NSArray *attacks = self.map.player.attacks;
	self.attackB1.hidden = true;
	self.attackB2.hidden = true;
	self.attackB3.hidden = true;
	self.attackB4.hidden = true;
	self.attackB5.hidden = true;
	self.attackB6.hidden = true;
	for (int i = 0; i < 6 && i < attacks.count - 6 * self.attackPage; i++)
	{
		UIButton *b;
		switch(i)
		{
			case 0: b = self.attackB1; break;
			case 1: b = self.attackB2; break;
			case 2: b = self.attackB3; break;
			case 3: b = self.attackB4; break;
			case 4: b = self.attackB5; break;
			case 5: b = self.attackB6; break;
		}
		[b setTitle:attacks[i + self.attackPage * 6] forState:UIControlStateNormal];
		b.hidden = false;
		UIColor *color = [self.map.player canUseAttack:attacks[i + self.attackPage * 6]] ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey");
		[b setTitleColor:color forState:UIControlStateNormal];
	}
	self.attackNext.hidden = attacks.count <= 6;
	[self.attackSelectPanel layoutIfNeeded];
	
	
	//set up attack confirm panel
	if (self.aoeIndicatorView == nil)
		self.attackConfirmLabel.text = [NSString stringWithFormat:@"Pick a target for %@.", self.attackChosen];
	else
		self.attackConfirmLabel.text = [NSString stringWithFormat:@"This is the area %@ will hit.\nTap again to confirm.", self.attackChosen];
	self.attackConfirmLabel.textColor = loadColorFromName(@"ui text");
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
	[self switchToPanel:panelCord withBlock:nil];
}

-(void)switchToPanel:(NSLayoutConstraint *)panelCord withBlock:(void (^)(void))block
{
	//you can still switch while uiAnimating, so that name labels can appear properly
	if (/*self.uiAnimating || */self.activePanelCord == panelCord)
		return;
	
	//TODO: there should be a duration constant
	
	panelCord.constant = -self.view.frame.size.width;
	[self.uiView layoutIfNeeded];
	
	__weak typeof(self) weakSelf = self;
	self.uiAnimating = true;
	[UIView animateWithDuration:0.2f animations:
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
		if (block != nil)
			block();
	}];
	
	self.activePanelCord = panelCord;
}

-(void)reloadAttackTargets
{
	int yStart = MAX(self.map.player.y - GAMEPLAY_TARGET_RANGE, 0);
	int xStart = MAX(self.map.player.x - GAMEPLAY_TARGET_RANGE, 0);
	for (int y = yStart; y < self.map.height && y < self.map.player.y + GAMEPLAY_TARGET_RANGE; y++)
		for (int x = xStart; x < self.map.width && x < self.map.player.x + GAMEPLAY_TARGET_RANGE; x++)
		{
			Tile *tile = self.map.tiles[y][x];
			if (self.attackChosen == nil)
				tile.targetLevel = TargetLevelOutOfRange;
			else
				tile.targetLevel = [self.map.player targetLevelAtX:x andY:y withAttack:self.attackChosen];
		}
	[self updateTiles];
}

#pragma mark user interaction

- (IBAction)pickAttack:(UIButton *)sender
{
	if (self.animating || self.uiAnimating)
		return;
	
	NSString *attackChosen = self.map.player.attacks[sender.tag + self.attackPage * 6];
	
	if (![self.map.player canUseAttack:attackChosen])
		return;
	
	self.attackChosen = attackChosen;
	NSLog(@"Picked attack #%li: %@", (long)sender.tag, self.attackChosen);
	
	[self reloadAttackTargets];
	[self reloadPanels];
	[self switchToPanel:self.attackConfirmPanelCord];
}

- (IBAction)pickNext
{
	if (self.animating || self.uiAnimating)
		return;
	NSArray *attacks = self.map.player.attacks;
	int numberPanels = (int)ceilf(attacks.count / 6.0f);
	self.attackPage = (self.attackPage + 1) % numberPanels;
	[self reloadPanels];
}

- (IBAction)pickCancel
{
	if (self.animating || self.uiAnimating)
		return;
	[self switchToPanel:self.mainPanelCord];
}

- (IBAction)cancelAttack
{
	if (self.animating || self.uiAnimating)
		return;
	
	if (self.aoeIndicatorView != nil)
	{
		[self.aoeIndicatorView removeFromSuperview];
		self.aoeIndicatorView = nil;
		[self reloadPanels];
	}
	else
	{
		self.attackChosen = nil;
		[self reloadAttackTargets];
		[self switchToPanel:self.attackSelectPanelCord];
	}
}


- (IBAction)attackButton
{
	if (self.animating || self.uiAnimating)
		return;
	
	self.attackPage = 0;
	[self reloadPanels];
	[self switchToPanel:self.attackSelectPanelCord];
}


-(void)tapGesture:(UITapGestureRecognizer *)sender
{
	if (self.animating || self.uiAnimating)
		return;
	
	CGPoint touchPoint = [sender locationInView:self.mapView];
	int x = ((int)floorf(touchPoint.x) - self.mapView.xOffset) / GAMEPLAY_TILE_SIZE;
	int y = ((int)floorf(touchPoint.y) - self.mapView.yOffset) / GAMEPLAY_TILE_SIZE;
	Tile *tile = self.map.tiles[y][x];

	NSLog(@"touched (%i %i), player is at (%i %i)", x, y, self.map.player.x, self.map.player.y);
	
	if (self.attackChosen != nil)
	{
		if (tile.targetLevel == TargetLevelTarget)
		{
			if (self.aoeIndicatorView == nil && loadValueBool(@"Attacks", self.attackChosen, @"area") && loadValueNumber(@"Attacks", self.attackChosen, @"area").intValue > 1)
			{
				//place an indicator
				int area = loadValueNumber(@"Attacks", self.attackChosen, @"area").intValue;
				UIImage *indSprite = [UIImage imageNamed:@"ui_warning"];
				UIImageView *indicator = [[UIImageView alloc] initWithImage:colorImage(indSprite, loadColorFromName(@"ui warning"))];
				indicator.frame = CGRectMake(GAMEPLAY_TILE_SIZE * (x - area / 2) + self.mapView.xOffset, GAMEPLAY_TILE_SIZE * (y - area / 2) + self.mapView.yOffset, GAMEPLAY_TILE_SIZE * area, GAMEPLAY_TILE_SIZE * area);
				[self.creatureView addSubview:indicator];
				self.aoeIndicatorView = indicator;
				[self reloadPanels];
			}
			else
			{
				if (self.aoeIndicatorView != nil)
				{
					[self.aoeIndicatorView removeFromSuperview];
					self.aoeIndicatorView = nil;
				}
				
				//use the attack
				[self.map.player useAttackWithName:self.attackChosen onX:x andY:y];
				
				//and switch the UI back
				self.attackChosen = nil;
				[self reloadAttackTargets];
//				[self switchToPanel:self.mainPanelCord];
			}
		}
		return;
	}
	
	
	//cancel whatever you are doing
	[self switchToPanel:self.mainPanelCord];
	
	
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
	
	//just don't draw tiles that aren't visible
	UIView *tileView = nil;
	if (tile.visible || tile.discovered)
	{
		//make the tile view
		tileView = [UIView new];
		tileView.backgroundColor = tile.color;
		
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
			targetView.alpha = 0.5; //TODO: this should be a constant
			[tileView addSubview:targetView];
		}
		
		//discovered but invisible tiles should be transparent
		if (!tile.visible && targetColor == nil)
			tileView.alpha = 0.5; //TODO: this should be a constant
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

#pragma mark: map delegate

-(void)moveCreatureCompleteWithBlock:(void (^)(void))block
{
	//recalculate who is hidden
	for (int i = 0; i < self.creatureViews.count; i++)
	{
		Creature *cr = self.map.creatures[i];
		UIView *view = self.creatureViews[i];
		view.hidden = !((Tile *)self.map.tiles[cr.y][cr.x]).visible || !([self.mapView isPointOnscreenWithX:cr.x andY:cr.y]);
	}
	
	//the action is over
	self.animating = false;
	block();
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

-(void)moveCreature:(Creature *)creature withBlock:(void (^)(void))block
{
	__weak typeof(self) weakSelf = self;
	self.animating = true;
	
	if (creature == self.map.player)
		[self.mapView setPositionWithX:creature.x - GAMEPLAY_SCREEN_WIDTH * 0.5f + 0.5f andY:creature.y - GAMEPLAY_SCREEN_HEIGHT * 0.5f + 0.5f withAnimBlock:
		^()
		{
			[weakSelf moveCreatureAnim];
		} andCompleteBlock:
		^()
		{
			[weakSelf moveCreatureCompleteWithBlock:block];
		}];
	else
		[UIView animateWithDuration:GAMEPLAY_MOVE_TIME animations:
		^()
		{
			[weakSelf moveCreatureAnim];
		} completion:
		^(BOOL finished)
		{
			[weakSelf moveCreatureCompleteWithBlock:block];
		}];
}

-(void)attackAnimation:(NSString *)name withElement:(NSString *)element fromPerson:(Creature *)creature targetX:(int)x andY:(int)y withEffectBlock:(void (^)(void))block
{
	//attack variables to relay to
	BOOL delayed = loadValueBool(@"Attacks", name, @"area");
	BOOL teleport = loadValueBool(@"Attacks", name, @"teleport");
	
	
	//TODO: I actually kinda liked the effect the background color changing thing had
	//maybe it can be added back, as a rider to the panel switch?
	//so, ie, the background turns red when someone uses a burn attack
	
	
	//announce the attack
	__weak typeof(self) weakSelf = self;
	self.attackNameLabel.text = [NSString stringWithFormat:@"%@ %@ %@!", creature.good ? @"Player" : @"Enemy", delayed ? @"unleashed" : @"used", name];
	self.attackNameLabel.textColor = loadColorFromName(@"ui text");
	[self switchToPanel:self.attackNamePanelCord withBlock:
	^()
	{
	
		//TODO: for now, everything has a "projectile" animation
		UIView *projectileView;
		projectileView = [[UIView alloc] initWithFrame:CGRectMake((creature.x + 0.25) * GAMEPLAY_TILE_SIZE + weakSelf.mapView.xOffset, (creature.y + 0.25) * GAMEPLAY_TILE_SIZE + weakSelf.mapView.yOffset, GAMEPLAY_TILE_SIZE / 2, GAMEPLAY_TILE_SIZE / 2)];
		[weakSelf.creatureView addSubview:projectileView];
		
		//set attack color by element
		if (!loadValueBool(@"Attacks", name, @"power"))
			projectileView.backgroundColor = loadColorFromName(@"element no damage");
		else
			projectileView.backgroundColor = loadColorFromName([NSString stringWithFormat:@"element %@", element]);
		

		weakSelf.animating = true;
		[UIView animateWithDuration:1.2f animations:
		^()
		{
			//fling the projectile at the target
			int projectileExtraSize = 0;
			if (delayed)
				projectileExtraSize = (loadValueNumber(@"Attacks", name, @"area").intValue / 2) * GAMEPLAY_TILE_SIZE;
			projectileView.frame = CGRectMake(x * GAMEPLAY_TILE_SIZE + weakSelf.mapView.xOffset - projectileExtraSize, y * GAMEPLAY_TILE_SIZE + weakSelf.mapView.yOffset - projectileExtraSize, GAMEPLAY_TILE_SIZE + projectileExtraSize * 2, GAMEPLAY_TILE_SIZE + projectileExtraSize * 2);
			
		} completion:
		^(BOOL finished)
		{
			//get rid of the projectile
			[projectileView removeFromSuperview];
			
			
			weakSelf.animating = false;
			
			//run the effect block
			block();
			
			[weakSelf switchToPanel:weakSelf.mainPanelCord withBlock:
			^()
			{
				if (teleport)
				{
					//move everyone
					[weakSelf.mapView setPositionWithX:weakSelf.map.player.x - GAMEPLAY_SCREEN_WIDTH * 0.5f + 0.5f andY:weakSelf.map.player.y - GAMEPLAY_SCREEN_HEIGHT * 0.5f + 0.5f withAnimBlock:
					^()
					{
						[weakSelf moveCreatureAnim];
					} andCompleteBlock:
					^()
					{
						[weakSelf.map recalculateVisibility];
						[weakSelf.mapView remake];
						if (!delayed)
							[weakSelf.map update];
					}];
				}
				else if (!delayed) //and now it's the next turn!
					[weakSelf.map update];
			}];
		}];
	}];
}

-(void)updateTiles
{
	[self.mapView remake];
}

-(void)updateStats
{
	[self reloadPanels];
}

@end
