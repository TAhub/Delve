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
#import "Item.h"
#import "ItemTableViewCell.h"
#import "ChangeMapViewController.h"

@interface GameViewController () <MapViewDelegate, MapDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet MapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *creatureView;
@property (weak, nonatomic) IBOutlet UIView *uiView;

@property (weak, nonatomic) IBOutlet UIView *mainPanel;
@property (weak, nonatomic) IBOutlet UIButton *pickUpButton;
@property (weak, nonatomic) IBOutlet UIButton *attacksButton;
@property (weak, nonatomic) IBOutlet UIButton *inventoryButton;
@property (weak, nonatomic) IBOutlet UIButton *craftButton;
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
@property (weak, nonatomic) IBOutlet UIButton *attackCancel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attackSelectPanelCord;

@property (weak, nonatomic) IBOutlet UIView *attackConfirmPanel;
@property (weak, nonatomic) IBOutlet UILabel *attackConfirmLabel;
@property (weak, nonatomic) IBOutlet UIButton *attackConfirmCancel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attackConfirmPanelCord;

@property (weak, nonatomic) IBOutlet UIView *attackNamePanel;
@property (weak, nonatomic) IBOutlet UILabel *attackNameLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attackNamePanelCord;

@property (weak, nonatomic) IBOutlet UIView *inventoryPanel;
@property (weak, nonatomic) IBOutlet UIView *inventoryContent;
@property (weak, nonatomic) IBOutlet UIButton *inventoryButtonTwo;
@property (weak, nonatomic) IBOutlet UIButton *inventoryButtonOne;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inventoryPanelCord;

@property (strong, nonatomic) NSMutableDictionary *preloadedTileImages;
@property (strong, nonatomic) Map* map;
@property (strong, nonatomic) NSMutableArray *creatureViews;
@property BOOL animating;
@property BOOL uiAnimating;
@property (weak, nonatomic) NSLayoutConstraint *activePanelCord;
@property int attackPage;
@property (strong, nonatomic) NSString *attackChosen;
@property (weak, nonatomic) UIView *aoeIndicatorView;

@property (strong, nonatomic) UITableView *itemTable;
@property (strong, nonatomic) Item *examinationItem;
@property (strong, nonatomic) NSArray *examineRecipies;
-(Item *)inventoryItemPicked;
-(NSString *)recipiePicked;

@end

@implementation GameViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.activePanelCord = nil;
	self.animating = false;
	self.uiAnimating = false;
	
	UITapGestureRecognizer *tappy = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
	[self.creatureView addGestureRecognizer:tappy];
	
	//format panels
	[self formatPanel:self.mainPanel];
	[self formatPanel:self.attackNamePanel];
	[self formatPanel:self.attackConfirmPanel];
	[self formatPanel:self.attackSelectPanel];
	[self formatPanel:self.inventoryPanel];
	
	//format buttons
	[self formatButton:self.attackB1];
	[self formatButton:self.attackB2];
	[self formatButton:self.attackB3];
	[self formatButton:self.attackB4];
	[self formatButton:self.attackB5];
	[self formatButton:self.attackB6];
	[self formatButton:self.attackNext];
	[self formatButton:self.attackCancel];
	[self formatButton:self.inventoryButton];
	[self formatButton:self.pickUpButton];
	[self formatButton:self.craftButton];
	[self formatButton:self.attacksButton];
	[self formatButton:self.attackConfirmCancel];
	[self formatButton:self.inventoryButtonOne];
	[self formatButton:self.inventoryButtonTwo];
}

-(void)loadMap:(Map *)map
{
	self.map = map;
	[self preloadTileImages];
	self.map.delegate = self;
}

-(void)preloadTileImageFor:(Tile *)tile
{
	if (tile.type != nil && tile.spriteName != nil && self.preloadedTileImages[tile.type] == nil)
	{
		UIImage *tileSprite = colorImage([UIImage imageNamed:tile.spriteName], tile.color);
		self.preloadedTileImages[tile.type] = tileSprite;
	}
}

-(void)preloadTileImages
{
	self.preloadedTileImages = [NSMutableDictionary new];
	for (NSArray *row in self.map.tiles)
		for (Tile *tile in row)
			[self preloadTileImageFor:tile];

}

-(void)regenerateCreatureSprite:(Creature *)cr
{
	int number = (int)[self.map.creatures indexOfObject:cr];
	UIView *view = self.creatureViews[number];
	[self regenerateCreatureSprite:cr atView:view];
}
-(void)regenerateCreatureSprite:(Creature *)cr atView:(UIView *)view
{
	//TODO: all boots are (so far) modeled after raider feet
	//but raider feet seem to be spaced 1 px further apart than human feet
	//which is, uh, a problem
	
	for (UIView *subView in view.subviews)
		[subView removeFromSuperview];
	
	if (cr.dead)
		return;
	
	//get info
	NSArray *colorations = loadValueArray(@"Races", cr.race, @"colorations");
	NSDictionary *coloration = colorations[cr.coloration];
	UIColor *skinColor = loadColorFromName((NSString *)coloration[@"skin"]);
	UIColor *hairColor = loadValueBool(@"Races", cr.race, @"hair styles") ? loadColorFromName((NSString *)coloration[@"hair"]) : nil;
	NSString *genderSuffix = loadValueBool(@"Races", cr.race, @"has gender") ? (cr.gender ? @"_f" : @"_m") : @"";
	
	NSMutableArray *images = [NSMutableArray new];
	NSMutableArray *yAdds = [NSMutableArray new];
	
	[self drawArmorsOf:cr withLayer:0 inArray:images withYAdds:yAdds genderSuffix:genderSuffix];
	
	NSString *bodySprite = [NSString stringWithFormat:@"%@%@", loadValueString(@"Races", cr.race, @"sprite"), genderSuffix];
	[images addObject:colorImage([UIImage imageNamed:bodySprite], skinColor)];
	[yAdds addObject:@(0)];
	
	[self drawArmorsOf:cr withLayer:1 inArray:images withYAdds:yAdds genderSuffix:genderSuffix];
	
	if (hairColor != nil)
	{
		NSString *hairSprite = [NSString stringWithFormat:@"%@_hair%i%@", loadValueString(@"Races", cr.race, @"sprite"), cr.hairStyle+1, genderSuffix];
		[images addObject:colorImage([UIImage imageNamed:hairSprite], hairColor)];
		[yAdds addObject:@(0)];
	}
	
	[self drawArmorsOf:cr withLayer:2 inArray:images withYAdds:yAdds genderSuffix:genderSuffix];
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:mergeImages(images, CGPointMake(0.5f, 1.0f), yAdds)];
	imageView.frame = CGRectMake(GAMEPLAY_TILE_SIZE / 2 - imageView.frame.size.width / 2, GAMEPLAY_TILE_SIZE - imageView.frame.size.height, imageView.frame.size.width, imageView.frame.size.height);
	[view addSubview:imageView];
	
	//stealth effect
	if (cr.stealthed > 0)
		view.alpha = 0.5f; //TODO: this should probably be a constant
	else
		view.alpha = 1;
}

-(void)drawArmorsOf:(Creature *)cr withLayer:(int)layer inArray:(NSMutableArray *)spriteArray withYAdds:(NSMutableArray *)yAdds genderSuffix:(NSString *)gS
{
	NSArray *raceYAdds = loadValueBool(@"Races", cr.race, @"armor slot y offsets") ? loadValueArray(@"Races", cr.race, @"armor slot y offsets") : nil;
	
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
				int yAdd = raceYAdds == nil ? 0 : ((NSNumber *)raceYAdds[i]).intValue;
				
				NSString *spriteName = loadValueString(@"Armors", armor, @"sprite");
				if (layer == 0)
					spriteName = [NSString stringWithFormat:@"%@_back", spriteName];
				if (loadValueBool(@"Armors", armor, @"sprite gender"))
					spriteName = [NSString stringWithFormat:@"%@%@", spriteName, gS];
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
	
	if (self.map == nil)
		[self loadMap:[[Map alloc] initWithMap:nil]];
	[self.map update];
	self.mapView.delegate = self;
	[self.mapView initializeMapAtX:self.map.player.x - GAMEPLAY_SCREEN_WIDTH * 0.5f + 0.5f andY:self.map.player.y - GAMEPLAY_SCREEN_HEIGHT * 0.5f + 0.5f];
	
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
	
	//set up UI panels
	[self reloadPanels];
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
	//in this order: blunt, cut, burn, shock
	[statLabel2 sizeToFit];
	statLabel2.textColor = loadColorFromName(@"ui text");
	[self.statView addSubview:statLabel2];
	
	
	//set button color
	//only bother to do this for buttons that change color
	[self.pickUpButton setTitleColor:self.map.canPickUp ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
	[self.inventoryButton setTitleColor:self.map.inventory.count > 0 ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
	[self.craftButton setTitleColor:[self.map canCraft] ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
	
	
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
		NSString *attack = attacks[i + self.attackPage * 6];
		[b setTitle:attack forState:UIControlStateNormal];
		b.hidden = false;
		UIColor *color = [self.map.player canUseAttack:attack] ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey");
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
	
	
	//set up inventory panel
	for (UIView *subview in self.inventoryContent.subviews)
		if (subview != self.itemTable)
			[subview removeFromSuperview];
	NSString *inventoryLabelText;
	if (self.examinationItem == nil)
	{
		inventoryLabelText = self.examineRecipies != nil ? @"Pick a recipie to craft" : @"Pick an item to use";
	}
	else
	{
		switch(self.examinationItem.type)
		{
			case ItemTypeArmor:
			case ItemTypeImplement:
			{
				int slot = [self.map.player slotForItem:self.examinationItem];
				if (slot == -1)
				{
					NSString *material = loadValueString(self.examinationItem.type == ItemTypeArmor ? @"Armors" : @"Implements", self.examinationItem.name, @"breaks into");
					inventoryLabelText = [NSString stringWithFormat:@"Break down %@ into %@?", self.examinationItem.name, material];
					[self.inventoryButtonOne setTitle:@"Break Down" forState:UIControlStateNormal];
					[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
					[self.inventoryButtonTwo setTitle:@"Cancel" forState:UIControlStateNormal];
					[self.inventoryButtonTwo setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
				}
				else
				{
					Tile *tile = self.map.tiles[self.map.player.y][self.map.player.x];
					if (tile.treasureType == TreasureTypeLocked)
					{
						[self.inventoryButtonOne setTitle:@"Unlock" forState:UIControlStateNormal];
						inventoryLabelText = [NSString stringWithFormat:@"This chest is locked.\nIt seems to contain a%@.", self.examinationItem.type == ItemTypeArmor ? @" piece of armor" : @"n implement"];
						if (self.map.player.hacks > 0)
							[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
						else
							[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
					}
					else
					{
						[self.inventoryButtonOne setTitle:@"Equip" forState:UIControlStateNormal];
						[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
						
						if (self.examinationItem.type == ItemTypeArmor)
						{
							NSString *comparison = self.map.player.armors[slot];
							NSString *armorDesc = [self.map.player armorDescription:self.examinationItem.name];
							NSString *eArmorDesc = (comparison == nil ? @"Nothing" : [self.map.player armorDescription:comparison]);
							inventoryLabelText = [NSString stringWithFormat:@"Equip %@?\n\n%@\n\nVS\n\n%@", self.examinationItem.name, armorDesc, eArmorDesc];
						}
						else
						{
							NSString *comparison;
							if (slot == -2)
								comparison = self.map.player.weapon;
							else
								comparison = self.map.player.implements[slot];
							NSString *weaponDesc = [self.map.player weaponDescription:self.examinationItem.name];
							NSString *eWeaponDesc = [self.map.player weaponDescription:comparison];
							inventoryLabelText = [NSString stringWithFormat:@"Equip %@?\n\n%@\n\nVS\n\n%@", self.examinationItem.name, weaponDesc, eWeaponDesc];
						}
					}
					
					[self.inventoryButtonTwo setTitle:@"Cancel" forState:UIControlStateNormal];
					[self.inventoryButtonTwo setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
				}
			}
				break;
			case ItemTypeInventory:
				inventoryLabelText = [NSString stringWithFormat:@"Pick up %@%@?", self.examinationItem.name, self.examinationItem.number > 1 ? [NSString stringWithFormat:@" x%i", self.examinationItem.number] : @""];
				
				//TODO: probably write some kind of description of the item, or something?
				//or maybe how many you have already, if you have any
				
				[self.inventoryButtonOne setTitle:@"Pick Up" forState:UIControlStateNormal];
				[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
				[self.inventoryButtonTwo setTitle:@"Cancel" forState:UIControlStateNormal];
				[self.inventoryButtonTwo setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
				break;
		}
	}
	UILabel *inventoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.inventoryContent.frame.size.width, self.inventoryContent.frame.size.height)];
	inventoryLabel.text = inventoryLabelText;
	inventoryLabel.textColor = loadColorFromName(@"ui text");
	if (self.examinationItem == nil)
	{
		[inventoryLabel sizeToFit];
		
		if (self.itemTable == nil)
		{
			self.itemTable = [[UITableView alloc] initWithFrame:CGRectMake(0, inventoryLabel.frame.size.height, self.inventoryContent.frame.size.width, self.inventoryContent.frame.size.height - inventoryLabel.frame.size.height)];
			[self.inventoryContent addSubview:self.itemTable];
			self.itemTable.delegate = self;
			self.itemTable.dataSource = self;
			self.itemTable.separatorStyle = UITableViewCellSeparatorStyleNone;
			[self.itemTable registerNib:[UINib nibWithNibName:@"ItemCell" bundle:nil] forCellReuseIdentifier:@"itemCell"];
		}
		else
		{
			NSIndexPath *oldPath = self.itemTable.indexPathForSelectedRow;
			[self.itemTable reloadData];
			[self.itemTable selectRowAtIndexPath:oldPath animated:NO scrollPosition:UITableViewScrollPositionTop];
		}
		
		if (self.examineRecipies != nil)
		{
			[self.inventoryButtonOne setTitle:@"Craft" forState:UIControlStateNormal];
			[self.inventoryButtonOne setTitleColor:(self.recipiePicked == nil ? loadColorFromName(@"ui text grey") : loadColorFromName(@"ui text")) forState:UIControlStateNormal];

		}
		else
		{
			[self.inventoryButtonOne setTitle:@"Use" forState:UIControlStateNormal];
			[self.inventoryButtonOne setTitleColor:(self.inventoryItemPicked == nil || !self.inventoryItemPicked.usable ? loadColorFromName(@"ui text grey") : loadColorFromName(@"ui text")) forState:UIControlStateNormal];
		}
		[self.inventoryButtonTwo setTitle:@"Cancel" forState:UIControlStateNormal];
		[self.inventoryButtonTwo setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
	}
	else
	{
		if (self.itemTable != nil)
		{
			[self.itemTable removeFromSuperview];
			self.itemTable = nil;
		}
		inventoryLabel.numberOfLines = 0;
		inventoryLabel.lineBreakMode = NSLineBreakByWordWrapping;
	}
	[self.inventoryContent addSubview:inventoryLabel];
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
	
	panelCord.constant = -self.view.frame.size.width;
//	[self.uiView layoutIfNeeded];
	[self.view layoutIfNeeded];
	
	__weak typeof(self) weakSelf = self;
	self.uiAnimating = true;
	[UIView animateWithDuration:GAMEPLAY_PANEL_TIME animations:
	^()
	{
		if (weakSelf.activePanelCord != nil)
			weakSelf.activePanelCord.constant = weakSelf.view.frame.size.width;
		panelCord.constant = 0;
//		[weakSelf.uiView layoutIfNeeded];
		[weakSelf.view layoutIfNeeded];
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
			tile.changed = true;
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

- (IBAction)craftButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	
	if (self.map.canCraft)
	{
		//open crafting menu
		self.examinationItem = nil;
		self.examineRecipies = self.map.preloadedCrafts;
		[self reloadPanels];
		[self switchToPanel:self.inventoryPanelCord];
	}
}

- (IBAction)attacksButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	
	self.attackPage = 0;
	[self reloadPanels];
	[self switchToPanel:self.attackSelectPanelCord];
}

- (IBAction)inventoryButtonPress:(UIButton *)sender
{
	if (self.animating || self.uiAnimating)
		return;
	
	if (self.examinationItem == nil)
	{
		//inventory screen
		if (sender.tag == 1)
		{
			if (self.examineRecipies != nil)
			{
				NSString *recipie = self.recipiePicked;
				if (recipie != nil)
				{
					Item *it = [self.map makeItemFromRecipie:recipie];
					[self.map payForRecipie:recipie];
					
					if (it.type != ItemTypeInventory)
					{
						Tile *tile = self.map.tiles[self.map.player.y][self.map.player.x];
						tile.treasureType = TreasureTypeBag;
						tile.treasure = it;
						tile.changed = true;
						[self updateTiles];
					}
					else
						[self.map addItem:it];
					
					[self reloadPanels];
					__weak typeof(self) weakSelf = self;
					[self switchToPanel:self.mainPanelCord withBlock:
					^()
					{
						[weakSelf.map update];
					}];
				}
				return;
			}
			
			Item *item = self.inventoryItemPicked;
			if (item != nil && item.usable)
			{
				NSString *floatText = @"";
				if (item.healing > 0)
				{
					//TODO: show a healing number
					int healingAmount = (item.healing * self.map.player.metabolism) / 100;
					self.map.player.health = MIN(self.map.player.health + healingAmount, self.map.player.maxHealth);
					floatText = [NSString stringWithFormat:@"%i", healingAmount];
				}
				//TODO: other effects (buffs, etc)
				item.number -= 1;
				
				//unload crafts
				self.map.preloadedCrafts = nil;
				
				//remove the item if it's at 0
				if (item.number == 0)
					[self.map.inventory removeObject:item];
				
				[self.itemTable reloadData];
				
				
				[self reloadPanels];
				__weak typeof(self) weakSelf = self;
				[self switchToPanel:self.mainPanelCord withBlock:
				^()
				{
					[weakSelf floatLabelsOn:[NSArray arrayWithObject:weakSelf.map.player] withString:[NSArray arrayWithObject:floatText] andColor:loadColorFromName(@"element heal") withBlock:
					^()
					{
						[weakSelf.map update];
					}];
				}];
			}
		}
		else
		{
			//cancel
			[self switchToPanel:self.mainPanelCord];
		}
		return;
	}
	
	Tile *tile = self.map.tiles[self.map.player.y][self.map.player.x];
	switch (self.examinationItem.type)
	{
		case ItemTypeArmor:
		case ItemTypeImplement:
			if (sender.tag == 1)
			{
				if (tile.treasureType == TreasureTypeLocked)
				{
					//unlock
					if (self.map.player.hacks > 0)
					{
						self.map.player.hacks -= 1;
						tile.treasureType = TreasureTypeChest;
						[self reloadPanels];
					}
					return;
				}
				
				int slot = [self.map.player slotForItem:self.examinationItem];
				if (slot == -1)
				{
					//convert to materials, and put them in your inventory
					NSString *material = loadValueString(self.examinationItem.type == ItemTypeArmor ? @"Armors" : @"Implements", self.examinationItem.name, @"breaks into");
					[self.map addItem:[[Item alloc] initWithName:material andType:ItemTypeInventory]];
					
					tile.treasure = nil;
					tile.treasureType = TreasureTypeNone;
					tile.changed = true;
					[self reloadPanels];
					[self updateTiles];
					
					//end turn
					__weak typeof(self) weakSelf = self;
					[self switchToPanel:self.mainPanelCord withBlock:
					^()
					{
						[weakSelf.map update];
					}];
				}
				else
				{
					//equip
					if (self.examinationItem.type == ItemTypeArmor)
					{
						tile.treasure = [[Item alloc] initWithName:self.map.player.armors[slot] andType:ItemTypeArmor];
						[self.map.player equipArmor:self.examinationItem];
						[self regenerateCreatureSprite:self.map.player];
					}
					else
					{
						if (slot == -2)
						{
							tile.treasure = [[Item alloc] initWithName:self.map.player.weapon andType:ItemTypeImplement];
							self.map.player.weapon = self.examinationItem.name;
						}
						else
						{
							tile.treasure = [[Item alloc] initWithName:self.map.player.implements[slot] andType:ItemTypeImplement];
							self.map.player.implements[slot] = self.examinationItem.name;
						}
					}
					
					//end turn
					[self reloadPanels];
					__weak typeof(self) weakSelf = self;
					[self switchToPanel:self.mainPanelCord withBlock:
					^()
					{
						[weakSelf.map update];
					}];
				}
			}
			else
			{
				//cancel
				[self switchToPanel:self.mainPanelCord];
			}
			break;
		case ItemTypeInventory:
			if (sender.tag == 1)
			{
				//add that item to your inventory
				
				//stack the item if possible
				[self.map addItem:self.examinationItem];
				
				
				tile.changed = true;
				tile.treasureType = TreasureTypeNone;
				[self updateTiles];
				[self reloadPanels];
				[self switchToPanel:self.mainPanelCord];
			}
			else
			{
				//cancel
				[self switchToPanel:self.mainPanelCord];
			}
			break;
	}
}

-(NSString *)recipiePicked
{
	if (self.itemTable == nil || self.itemTable.indexPathForSelectedRow == nil)
		return nil;
	int row = (int)self.itemTable.indexPathForSelectedRow.row;
	return self.examineRecipies[row];
}

-(Item *)inventoryItemPicked
{
	if (self.itemTable == nil || self.itemTable.indexPathForSelectedRow == nil)
		return nil;
	int row = (int)self.itemTable.indexPathForSelectedRow.row;
	return self.map.inventory[row];
}

- (IBAction)inventoryOpenButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	if (self.map.inventory.count > 0)
	{
		//opens the inventory so you can use inventory buttons
		self.examinationItem = nil;
		self.examineRecipies = nil;
		[self reloadPanels];
		[self switchToPanel:self.inventoryPanelCord];
	}
}


- (IBAction)pickUpButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	if (self.map.canPickUp)
	{
		Tile *tile = self.map.tiles[self.map.player.y][self.map.player.x];
		self.examinationItem = tile.treasure;
		self.examineRecipies = nil;
		if (self.itemTable != nil)
		{
			[self.itemTable removeFromSuperview];
			self.itemTable = nil;
		}
		[self reloadPanels];
		[self switchToPanel:self.inventoryPanelCord];
	}
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
	if (tile.treasureType != TreasureTypeNone)
	{
		//TODO: get the real treasure image
		UIImage *treasureSprite = [UIImage imageNamed:@"ui_warning"];
		treasureSprite = colorImage(treasureSprite, loadColorFromName(@"gold"));
		
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

-(void)recalculateHidden
{
	for (int i = 0; i < self.creatureViews.count; i++)
	{
		Creature *cr = self.map.creatures[i];
		UIView *view = self.creatureViews[i];
		view.hidden = !((Tile *)self.map.tiles[cr.y][cr.x]).visible || !([self.mapView isPointOnscreenWithX:cr.x andY:cr.y]);
	}
}

#pragma mark: map delegate

-(void)moveCreatureCompleteWithBlock:(void (^)(void))block
{
	//the action is over
	self.animating = false;
	[self recalculateHidden];
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

-(void)attackAnimation:(NSString *)name withElement:(NSString *)element fromPerson:(Creature *)creature targetX:(int)x andY:(int)y withEffectBlock:(void (^)(void (^)(void)))block
{
	//attack variables to relay to
	BOOL delayed = loadValueBool(@"Attacks", name, @"area");
	BOOL teleport = loadValueBool(@"Attacks", name, @"teleport");
	
	
	//TODO: I actually kinda liked the effect the background color changing thing had
	//maybe it can be added back, as a rider to the panel switch?
	//so, ie, the background turns red when someone uses a burn attack
	
	
	//load attack effect variables
	NSString *attackEffect = loadValueString(@"Attacks", name, @"attack effect");
	NSString *attackSpriteName = loadValueString(@"AttackEffects", attackEffect, @"sprite");
	UIImage *attackSprite = [UIImage imageNamed:attackSpriteName];
	
	//set attack color by element
	if (!loadValueBool(@"Attacks", name, @"power"))
		attackSprite = colorImage(attackSprite, loadColorFromName(@"element no damage"));
	else
		attackSprite = colorImage(attackSprite, loadColorFromName([NSString stringWithFormat:@"element %@", element]));
	
	float time;
	if (loadValueBool(@"AttackEffects", attackEffect, @"time per distance"))
		time = loadValueNumber(@"AttackEffects", attackEffect, @"time per distance").floatValue * (ABS(creature.x - x) + ABS(creature.y - y));
	else
		time = loadValueNumber(@"AttackEffects", attackEffect, @"time").floatValue;
	
	int attackXFrom, attackYFrom, attackXTo, attackYTo;
	BOOL rotate = loadValueBool(@"AttackEffects", attackEffect, @"rotate");
	float angle = 0;
	
	//TODO: pick relative positions based on anim type
	NSString *animType = loadValueString(@"AttackEffects", attackEffect, @"type");
	attackXTo = x * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2 + self.mapView.xOffset;
	attackYTo = y * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2 + self.mapView.yOffset;
	if ([animType isEqualToString:@"projectile"])
	{
		attackXFrom = creature.x * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2 + self.mapView.xOffset;
		attackYFrom = creature.y * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2 + self.mapView.yOffset;
	}
	else if ([animType isEqualToString:@"down melee"])
	{
		attackXFrom = attackXTo;
		attackYFrom = attackYTo - GAMEPLAY_TILE_SIZE;
		attackYTo += GAMEPLAY_TILE_SIZE / 2;
	}
	else if ([animType isEqualToString:@"up melee"])
	{
		attackXFrom = attackXTo;
		attackYFrom = attackYTo + GAMEPLAY_TILE_SIZE;
		attackYTo -= GAMEPLAY_TILE_SIZE / 2;
	}
	if (rotate)
		angle = atan2f(attackYTo - attackYFrom, attackXTo - attackXFrom);
	
	
	//announce the attack
	__weak typeof(self) weakSelf = self;
	self.attackNameLabel.text = [NSString stringWithFormat:@"%@ %@ %@!", creature.good ? @"Player" : @"Enemy", delayed ? @"unleashed" : @"used", name];
	self.attackNameLabel.textColor = loadColorFromName(@"ui text");
	[self switchToPanel:self.attackNamePanelCord withBlock:
	^()
	{
		//TODO: for now, everything has a "projectile" animation
		UIView *projectileView = [UIView new];
		UIImageView *image = [[UIImageView alloc] initWithImage:attackSprite];
		image.center = CGPointZero;
		projectileView.center = CGPointMake(attackXFrom, attackYFrom);
		[weakSelf.creatureView addSubview:projectileView];
		[projectileView addSubview:image];
		if (rotate)
			image.transform = CGAffineTransformMakeRotation(angle);
		
		
		//how long should it last?
		float finalTime = time;
		Tile *to = weakSelf.map.tiles[y][x];
		Tile *from = weakSelf.map.tiles[creature.y][creature.x];
		if (!to.visible && !from.visible && !delayed)
			finalTime = 0.001f; //you can't see what's attacking, or what's being attacked, so it should be invisible; area attacks are exempt
		weakSelf.animating = true;
		[UIView animateWithDuration:finalTime animations:
		^()
		{
			//fling the projectile at the target
			if (delayed)
			{
				int projectileExtraSize = loadValueNumber(@"Attacks", name, @"area").intValue;
				int width = image.bounds.size.width * projectileExtraSize;
				int height = image.bounds.size.height * projectileExtraSize;
				image.bounds = CGRectMake(-width, -height, width, height);
			}
			projectileView.frame = CGRectMake(attackXTo, attackYTo, 0, 0);
			
		} completion:
		^(BOOL finished)
		{
			//get rid of the projectile
			[projectileView removeFromSuperview];
			
			
			weakSelf.animating = false;
			
			//run the effect block
			block(^(){
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
			});
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

-(void)updateCreature:(Creature *)cr
{
	[self regenerateCreatureSprite:cr];
}

-(void)goToNextMap
{
	[self performSegueWithIdentifier:@"changeMap" sender:self];
}

-(void)floatLabelsOn:(NSArray *)creatures withString:(NSArray *)strings andColor:(UIColor *)color withBlock:(void (^)(void))block
{
	NSMutableArray *labels = [NSMutableArray new];
	for (int i = 0; i < creatures.count; i++)
	{
		Creature *cr = creatures[i];
		NSString *string = strings[i];
		if ([self.mapView isPointOnscreenWithX:cr.x andY:cr.y] && string.length > 0)
		{
			UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
			label.text = string;
			label.textColor = color;
			[label sizeToFit];
			label.center = CGPointMake((cr.x + 0.5f) * GAMEPLAY_TILE_SIZE + self.mapView.xOffset, (cr.y + 0.5f) * GAMEPLAY_TILE_SIZE + self.mapView.yOffset);
			[self.creatureView addSubview:label];
			[labels addObject:label];
		}
	}
	
	if (labels.count == 0)
	{
		block();
		return;
	}
	
	self.uiAnimating = true;
	
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:GAMEPLAY_LABEL_TIME animations:
	^()
	{
		for (UIView *label in labels)
			label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y - GAMEPLAY_LABEL_DISTANCE, label.frame.size.width, label.frame.size.height);
	} completion:
	^(BOOL complete)
	{
		weakSelf.uiAnimating = false;
		for (UIView *label in labels)
			[label removeFromSuperview];
		block();
	}];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	//make everything invisible
	self.view.hidden = true;
	
	ChangeMapViewController *change = segue.destinationViewController;
	[change loadMap:self.map];
}

#pragma mark table view delegate and datasource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.examineRecipies != nil)
		return (int)self.examineRecipies.count;
	return (int)self.map.inventory.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ItemTableViewCell *itemCell = [tableView dequeueReusableCellWithIdentifier:@"itemCell"];
	if (self.examineRecipies == nil)
	{
		Item *item = self.map.inventory[indexPath.row];
		itemCell.nameLabel.text = item.name;
	}
	else
	{
		//TODO: print recipie details
		NSString *recipie = self.examineRecipies[indexPath.row];
		itemCell.nameLabel.text = recipie;
	}
	itemCell.nameLabel.textColor = loadColorFromName(@"ui text");
	return itemCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self reloadPanels];
}

@end
