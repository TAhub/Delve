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
#import "CharacterServices.h"
#import "DefeatViewController.h"
#import "SoundPlayer.h"

@interface GameViewController () <UITableViewDelegate, UITableViewDataSource, MapDelegate>

@property (weak, nonatomic) IBOutlet UIView *uiView;

@property (weak, nonatomic) IBOutlet UIView *mainPanel;
@property (weak, nonatomic) IBOutlet UIButton *pickUpButton;
@property (weak, nonatomic) IBOutlet UIButton *attacksButton;
@property (weak, nonatomic) IBOutlet UIButton *defendButton;
@property (weak, nonatomic) IBOutlet UIButton *inventoryButton;
@property (weak, nonatomic) IBOutlet UIButton *craftButton;
@property (weak, nonatomic) IBOutlet UIButton *examineButton;
@property (weak, nonatomic) IBOutlet UIView *statView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainPanelCord;


@property (weak, nonatomic) IBOutlet UIView *repeatPromptPanel;
@property (weak, nonatomic) IBOutlet UIButton *repeatButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *repeatPromptCord;


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

@property (weak, nonatomic) IBOutlet UIView *examinePanel;
@property (weak, nonatomic) IBOutlet UIButton *examinePanelBack;
@property (weak, nonatomic) IBOutlet UIView *examinePanelContents;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *examinePanelCord;


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
@property (weak, nonatomic) IBOutlet UIButton *inventoryButtonBreak;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inventoryPanelCord;

@property (weak, nonatomic) NSLayoutConstraint *activePanelCord;
@property int attackPage;
@property (weak, nonatomic) UIView *aoeIndicatorView;
@property int aoeIndicatorX;
@property int aoeIndicatorY;

@property (strong, nonatomic) UITableView *itemTable;
@property (strong, nonatomic) Item *examinationItem;
@property (strong, nonatomic) NSArray *examineRecipies;
-(Item *)inventoryItemPicked;
-(NSString *)recipiePicked;

@property (weak, nonatomic) Creature *examinationCreature;

@property (strong, nonatomic) NSString *lastAttack;
@property (weak, nonatomic) Creature *lastTarget;

@end

@implementation GameViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.activePanelCord = nil;
	self.animating = false;
	self.uiAnimating = false;
	
	self.lastAttack = nil;
	
	UITapGestureRecognizer *tappy = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
	[self.creatureView addGestureRecognizer:tappy];
	
	//format panels
	[self formatPanel:self.mainPanel];
	[self formatPanel:self.attackNamePanel];
	[self formatPanel:self.attackConfirmPanel];
	[self formatPanel:self.attackSelectPanel];
	[self formatPanel:self.inventoryPanel];
	[self formatPanel:self.repeatPromptPanel];
	[self formatPanel:self.examinePanel];
	
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
    [self formatButton:self.defendButton];
	[self formatButton:self.attackConfirmCancel];
	[self formatButton:self.inventoryButtonOne];
	[self formatButton:self.inventoryButtonTwo];
	[self formatButton:self.inventoryButtonBreak];
	[self formatButton:self.repeatButton];
	[self formatButton:self.examineButton];
	[self formatButton:self.examinePanelBack];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.map.delegate = self;
	[self.map update];
	
	//set up UI panels
	[self reloadPanels];
}

-(void)reloadPanels
{
	//reload the info panel
	makeInfoLabelInView(self.map.player, self.statView, self.map.countdown);
	
	
	//set button color
	//only bother to do this for buttons that change color
	[self.pickUpButton setTitleColor:self.map.canPickUp ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
	[self.inventoryButton setTitleColor:self.map.inventory.count > 0 ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
	[self.craftButton setTitleColor:[self.map canCraft] ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
	
	
	//set up attacks panel with a list of attacks (greyed out buttons for attacks you can't use)
	if (self.activePanelCord == self.attackSelectPanelCord)
	{
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
			NSNumber *cooldown = self.map.player.cooldowns[attack];
			[b setTitle:(cooldown != nil && cooldown.intValue > 0 ? [NSString stringWithFormat:@"%@ (%i)", attack, cooldown.intValue] : attack) forState:UIControlStateNormal];
			b.hidden = false;
			UIColor *color;
			if ([self.map.player canUseAttack:attack])
			{
//				NSString *element = [self.map.player elementForAttack:attack];
				
				//TODO: if element isn't nil, display a little elemental orb too
				
				color = loadColorFromName(@"ui text");
			}
			else
				color = loadColorFromName(@"ui text grey");
			[b setTitleColor:color forState:UIControlStateNormal];
		}
		self.attackNext.hidden = attacks.count <= 6;
		[self.attackSelectPanel layoutIfNeeded];
	}
	
	
	//set up attack confirm panel
	if (self.activePanelCord == self.attackConfirmPanelCord)
	{
		if (self.aoeIndicatorView == nil)
			self.attackConfirmLabel.text = [NSString stringWithFormat:@"Pick a target for %@.", self.attackChosen];
		else
			self.attackConfirmLabel.text = [NSString stringWithFormat:@"This is the area %@ will hit.\nTap again to confirm.", self.attackChosen];
		self.attackConfirmLabel.textColor = loadColorFromName(@"ui text");
	}
	
	
	//set up inventory panel
	if (self.activePanelCord == self.inventoryPanelCord)
	{
		self.inventoryButtonBreak.hidden = true;
		
		for (UIView *subview in self.inventoryContent.subviews)
			if (subview != self.itemTable)
				[subview removeFromSuperview];
		NSString *inventoryLabelText;
		if (self.examinationItem == nil)
		{
			inventoryLabelText = self.examineRecipies != nil ? @"Pick a recipie to craft" : @"Pick an item to use";
			if (self.examineRecipies == nil && self.inventoryItemPicked != nil)
			{
				Item *picked = [self inventoryItemPicked];
				inventoryLabelText = [picked itemDescriptionWithCreature:self.map.player];
			}
			else if (self.examineRecipies != nil && self.recipiePicked != nil)
			{
				Item *sample = [self.map makeItemFromRecipie:self.recipiePicked];
				inventoryLabelText = [sample itemDescriptionWithCreature:self.map.player];
				
			}
		}
		else
		{
			switch(self.examinationItem.type)
			{
				case ItemTypeArmor:
				case ItemTypeImplement:
				{
					Tile *tile = self.map.tiles[self.map.player.y][self.map.player.x];
					if (tile.treasureType == TreasureTypeLocked)
					{
						[self.inventoryButtonOne setTitle:@"Unlock" forState:UIControlStateNormal];
						[self.inventoryButtonTwo setTitle:@"Cancel" forState:UIControlStateNormal];
						inventoryLabelText = [NSString stringWithFormat:@"This chest is locked.\nIt seems to contain a%@.", self.examinationItem.type == ItemTypeArmor ? @" piece of armor" : @"n implement"];
						if (self.map.player.hacks > 0)
							[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
						else
							[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
					}
					else
					{
						NSString *material = loadValueString(self.examinationItem.type == ItemTypeArmor ? @"Armors" : @"Implements", self.examinationItem.name, @"breaks into");
						inventoryLabelText = [NSString stringWithFormat:@"Break down %@ into %@?", self.examinationItem.name, material];
						
						int slot = [self.map.player slotForItem:self.examinationItem];
						if (slot == -1)
						{
							[self.inventoryButtonOne setTitle:@"Break Down" forState:UIControlStateNormal];
							[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
							[self.inventoryButtonTwo setTitle:@"Cancel" forState:UIControlStateNormal];
							[self.inventoryButtonTwo setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
						}
						else
						{
							[self.inventoryButtonOne setTitle:@"Equip" forState:UIControlStateNormal];
							[self.inventoryButtonOne setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
							
							//set the break down button to not-hidden, so you can break down
							self.inventoryButtonBreak.hidden = false;
							
							if (self.examinationItem.type == ItemTypeArmor)
							{
								NSString *comparison = self.map.player.armors[slot];
								NSString *armorDesc = [self.map.player armorDescription:self.examinationItem.name];
								NSString *eArmorDesc = (comparison == nil ? @"Nothing" : [self.map.player armorDescription:comparison]);
								inventoryLabelText = [NSString stringWithFormat:@"Equip %@?\n\n%@\n\nVS\n\n%@\n\nOR\n\n%@", self.examinationItem.name, armorDesc, eArmorDesc, inventoryLabelText];
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
								inventoryLabelText = [NSString stringWithFormat:@"Equip %@?\n\n%@\n\nVS\n\n%@\n\nOR\n\n%@", self.examinationItem.name, weaponDesc, eWeaponDesc, inventoryLabelText];
							}
							
							[self.inventoryButtonTwo setTitle:@"Cancel" forState:UIControlStateNormal];
							[self.inventoryButtonTwo setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
						}
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
		inventoryLabel.numberOfLines = 0;
		inventoryLabel.textColor = loadColorFromName(@"ui text");
		if (self.examinationItem == nil)
		{
			[inventoryLabel sizeToFit];
			CGRect tableFrame = CGRectMake(0, inventoryLabel.frame.size.height, self.inventoryContent.frame.size.width, self.inventoryContent.frame.size.height - inventoryLabel.frame.size.height);
			
			if (self.itemTable == nil)
			{
				self.itemTable = [[UITableView alloc] initWithFrame:tableFrame];
				[self.inventoryContent addSubview:self.itemTable];
				self.itemTable.delegate = self;
				self.itemTable.dataSource = self;
				self.itemTable.separatorStyle = UITableViewCellSeparatorStyleNone;
				[self.itemTable registerNib:[UINib nibWithNibName:@"ItemCell" bundle:nil] forCellReuseIdentifier:@"itemCell"];
			}
			else
			{
				NSIndexPath *oldPath = self.itemTable.indexPathForSelectedRow;
				self.itemTable.frame = tableFrame;
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
	
	if (self.activePanelCord == self.examinePanelCord)
	{
		//set up examination stuff
		for (UIView *subview in self.examinePanelContents.subviews)
			[subview removeFromSuperview];
		if (self.examinationCreature != nil)
			makeExamineLabelInView(self.examinationCreature, self.examinePanelContents);
		else
		{
			UILabel *desc = [[UILabel alloc] initWithFrame:CGRectZero];
			desc.text = @"Pick a creature to examine.";
			desc.textColor = loadColorFromName(@"ui text");
			[desc sizeToFit];
			[self.examinePanelContents addSubview:desc];
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
	[self switchToPanel:panelCord withBlock:nil];
}

-(void)switchToPanel:(NSLayoutConstraint *)panelCord withBlock:(void (^)(void))block
{
	//you can still switch while uiAnimating, so that name labels can appear properly
	if (/*self.uiAnimating || */self.activePanelCord == panelCord)
	{
		if (block != nil)
			block();
		return;
	}
	
	panelCord.constant = 0;
//	[self.uiView layoutIfNeeded];
	[self.view layoutIfNeeded];
	
	__weak typeof(self) weakSelf = self;
	self.uiAnimating = true;
	[UIView animateWithDuration:GAMEPLAY_PANEL_TIME animations:
	^()
	{
		if (weakSelf.activePanelCord != nil)
			weakSelf.activePanelCord.constant = 2 * weakSelf.view.frame.size.width;
		panelCord.constant = weakSelf.view.frame.size.width;
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
	[self reloadPanels];
}

-(void)reloadAttackTargets:(BOOL)forExamine
{
	int yStart = MAX(self.map.player.y - GAMEPLAY_TARGET_RANGE, 0);
	int xStart = MAX(self.map.player.x - GAMEPLAY_TARGET_RANGE, 0);
	for (int y = yStart; y < self.map.height && y < self.map.player.y + GAMEPLAY_TARGET_RANGE; y++)
		for (int x = xStart; x < self.map.width && x < self.map.player.x + GAMEPLAY_TARGET_RANGE; x++)
		{
			Tile *tile = self.map.tiles[y][x];
			
			if (forExamine)
			{
				if (self.examinationCreature != nil)
					tile.targetLevel = tile.inhabitant == self.examinationCreature ? TargetLevelTarget : TargetLevelOutOfRange;
				else
					tile.targetLevel = (tile.inhabitant != nil && !tile.inhabitant.good) ? TargetLevelInRange : TargetLevelOutOfRange;
			}
			else if (self.attackChosen == nil)
				tile.targetLevel = TargetLevelOutOfRange;
			else
				tile.targetLevel = [self.map.player targetLevelAtX:x andY:y withAttack:self.attackChosen];
			tile.changed = true;
		}
	[self updateTiles];
}

#pragma mark map delegate

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

-(void)presentRepeatPrompt
{
	//CAN you repeat?)
	if (self.lastTarget.dead)
		self.lastTarget = nil;
	
	if (self.lastAttack == nil || self.lastTarget == nil || ![self.map.player canUseAttack:self.lastAttack] || [self.map.player targetLevelAtX:self.lastTarget.x andY:self.lastTarget.y withAttack:self.lastAttack] != TargetLevelTarget)
		return;
	
	//set the repeat prompt's text
	[self.repeatButton setTitle:[NSString stringWithFormat:@"Press to use %@ again.", self.lastAttack] forState:UIControlStateNormal];
	
	self.uiAnimating = true;
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:GAMEPLAY_PANEL_TIME animations:
	 ^()
	 {
		 weakSelf.repeatPromptCord.constant = 0;
		 [weakSelf.view layoutIfNeeded];
	 } completion:
	 ^(BOOL complete)
	 {
		 weakSelf.uiAnimating = false;
	 }];
}

-(void)attackAnimation:(NSString *)name withElement:(NSString *)element suffix:(NSString *)suffix andAttackEffect:(NSString *)attackEffect fromPerson:(Creature *)creature targetX:(int)x andY:(int)y withEffectBlock:(void (^)(void (^)(void)))block andEndBlock:(void (^)(void))endBlock
{
	//attack variables to relay to
	BOOL delayed = loadValueBool(@"Attacks", name, @"area");
	BOOL teleport = loadValueBool(@"Attacks", name, @"teleport");
	
	//this function has all the gameplay code for the animation
	__weak typeof(self) weakSelf = self;
	[self attackAnimationInner:name withElement:element suffix:suffix andAttackEffect:attackEffect fromPerson:creature targetX:x andY:y delayed:delayed withEffectBlock:
	 ^()
	 {
		 block(^(){
			 [weakSelf switchToPanel:weakSelf.mainPanelCord withBlock:
			  ^()
			  {
				  //NOTE:
				  //if this is a counter-attack, this final block won't happen
				  
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
						   endBlock();
					   }];
				  }
				  else
					  endBlock();
			  }];
		 });
	 }];
}

-(void)attackAnimationInner:(NSString *)name withElement:(NSString *)element suffix:(NSString *)suffix andAttackEffect:(NSString *)attackEffect fromPerson:(Creature *)creature targetX:(int)x andY:(int)y delayed:(BOOL)delayed withEffectBlock:(void (^)(void))block
{
	//set attack color by element
	UIColor *color;
	if (!loadValueBool(@"Attacks", name, @"power"))
		color = loadColorFromName(@"element no damage");
	else
		color = loadColorFromName([NSString stringWithFormat:@"element %@", element]);
	
	
	//pick relative positions based on anim type
	int attackXFrom, attackYFrom, attackXTo, attackYTo;
	BOOL rotate = loadValueBool(@"AttackEffects", attackEffect, @"rotate");
	BOOL projectile = true;
	float angle = 0;
	NSString *animType = loadValueString(@"AttackEffects", attackEffect, @"type");
	attackXTo = x * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2 + self.mapView.xOffset;
	attackYTo = y * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2 + self.mapView.yOffset;
	if ([animType isEqualToString:@"projectile"])
	{
		attackXFrom = creature.x * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2 + self.mapView.xOffset;
		attackYFrom = creature.y * GAMEPLAY_TILE_SIZE + GAMEPLAY_TILE_SIZE / 2 + self.mapView.yOffset;
	}
	else if ([animType isEqualToString:@"melee"])
	{
		attackXFrom = attackXTo;
		attackYFrom = attackYTo + loadValueNumber(@"AttackEffects", attackEffect, @"start off").intValue;
		attackYTo += loadValueNumber(@"AttackEffects", attackEffect, @"end off").intValue;
	}
	else
		projectile = false;
	if (rotate)
		angle = atan2f(attackYTo - attackYFrom, attackXTo - attackXFrom);
	
	
	//load attack effect variables
	UIImage *attackSprite = nil;
	float projectileScale = 1;
	if (projectile)
	{
		NSString *attackSpriteName = loadValueString(@"AttackEffects", attackEffect, @"sprite");
		attackSprite = colorImage([UIImage imageNamed:attackSpriteName], color);
		if (loadValueBool(@"AttackEffects", attackEffect, @"projectile scale"))
			projectileScale = loadValueNumber(@"AttackEffects", attackEffect, @"projectile scale").floatValue;
	}
	
	//load explosion effect variables
	UIImage *explosionSprite = nil;
	if (loadValueBool(@"AttackEffects", attackEffect, @"explosion sprite"))
	{
		NSString *explosionSpriteName = loadValueString(@"AttackEffects", attackEffect, @"explosion sprite");
		explosionSprite = colorImage([UIImage imageNamed:explosionSpriteName], color);
	}
	
	
	//how long should it last?
	Tile *to = self.map.tiles[y][x];
	Tile *from = self.map.tiles[creature.y][creature.x];
	float time, explosionTime = 0;
	if (loadValueBool(@"AttackEffects", attackEffect, @"time per distance"))
		time = loadValueNumber(@"AttackEffects", attackEffect, @"time per distance").floatValue * (ABS(creature.x - x) + ABS(creature.y - y));
	else if (loadValueBool(@"AttackEffects", attackEffect, @"time"))
		time = loadValueNumber(@"AttackEffects", attackEffect, @"time").floatValue;
	else
		time = 0.001f;
	if (loadValueBool(@"AttackEffects", attackEffect, @"explosion time"))
		explosionTime = loadValueNumber(@"AttackEffects", attackEffect, @"explosion time").floatValue;
	if (!to.visible && !from.visible && !delayed)
	{
		//you can't see what's attacking, or what's being attacked, so it should be invisible; area attacks are exempt
		time = 0.001f;
		explosionTime = time;
	}
	
	//announce the attack
	__weak typeof(self) weakSelf = self;
	if (suffix != nil)
		self.attackNameLabel.text = [NSString stringWithFormat:@"%@ attacked %@!", creature.name, suffix];
	else
		self.attackNameLabel.text = [NSString stringWithFormat:@"%@ %@ %@!", creature.name, delayed ? @"unleashed" : @"used", name];
	self.attackNameLabel.textColor = loadColorFromName(@"ui text");
	[self switchToPanel:self.attackNamePanelCord withBlock:
	 ^()
	 {
		 UIView *projectileView = nil;
		 UIImageView *image = nil;
		 if (projectile)
		 {
			 projectileView = [UIView new];
			 image = [[UIImageView alloc] initWithImage:attackSprite];
			 int width = attackSprite.size.width * projectileScale;
			 int height = attackSprite.size.height * projectileScale;
			 image.frame = CGRectMake(-width/2, -height/2, width, height);
			 projectileView.center = CGPointMake(attackXFrom, attackYFrom);
			 [weakSelf.creatureView addSubview:projectileView];
			 [projectileView addSubview:image];
			 if (rotate)
				 image.transform = CGAffineTransformMakeRotation(angle);
		 }
		 
		 
		 weakSelf.animating = true;
		 [UIView animateWithDuration:time animations:
		  ^()
		  {
			  //fling the projectile at the target
			  if (projectile)
			  {
				  if (delayed && explosionSprite == nil) //only expand when there's no explosion
				  {
					  int projectileExtraSize = loadValueNumber(@"Attacks", name, @"area").intValue;
					  int width = image.bounds.size.width * projectileExtraSize;
					  int height = image.bounds.size.height * projectileExtraSize;
					  image.bounds = CGRectMake(-width, -height, width, height);
				  }
				  projectileView.frame = CGRectMake(attackXTo, attackYTo, 0, 0);
			  }
			  
		  } completion:
		  ^(BOOL finished)
		  {
			  //get rid of the projectile
			  if (projectile)
				  [projectileView removeFromSuperview];
			  
			  if (explosionSprite == nil)
			  {
				  weakSelf.animating = false;
				  block();
			  }
			  else
			  {
				  UIImageView *boom = [[UIImageView alloc] initWithImage:explosionSprite];
				  boom.frame = CGRectMake(attackXTo - GAMEPLAY_TILE_SIZE / 4, attackYTo - GAMEPLAY_TILE_SIZE / 4, GAMEPLAY_TILE_SIZE / 2, GAMEPLAY_TILE_SIZE / 2);
				  [weakSelf.creatureView addSubview:boom];
				  [UIView animateWithDuration:explosionTime animations:
				   ^()
				   {
					   int boomSize = 1;
					   if (delayed)
						   boomSize = loadValueNumber(@"Attacks", name, @"area").intValue;
					   boom.frame = CGRectMake(attackXTo - GAMEPLAY_TILE_SIZE * boomSize / 2, attackYTo - GAMEPLAY_TILE_SIZE * boomSize / 2, GAMEPLAY_TILE_SIZE * boomSize, GAMEPLAY_TILE_SIZE * boomSize);
				   } completion:
				   ^(BOOL finished)
				   {
					   [boom removeFromSuperview];
					   
					   weakSelf.animating = false;
					   block();
				   }];
			  }
		  }];
	 }];
}

-(void)updateStats
{
	[self reloadPanels];
}

-(void)countdownWarningWithBlock:(void (^)(void))block
{
	[self reloadPanels];
	
	int countdown = self.map.countdown;
	
	//	NSLog(@"COUNTDOWN: %i", countdown);
	
	if (countdown % GAMEPLAY_COUNTDOWN_WARNING_INTERVAL != 0)
	{
		//don't warn about the countdown
		block();
		return;
	}
	
	UILabel *warning = [[UILabel alloc] initWithFrame:CGRectZero];
	warning.text = [NSString stringWithFormat:@"YOU HAVE %i ROUNDS TO ESCAPE!", countdown];
	warning.textColor = loadColorFromName(@"ui warning");
	[warning sizeToFit];
	warning.center = self.creatureView.center;
	[self.view addSubview:warning];
	
	[[SoundPlayer sharedPlayer] playSound:@"siren"];
	
	self.animating = true;
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:0.3f animations:
	 ^()
	 {
		 weakSelf.view.backgroundColor = loadColorFromName(@"ui warning");
	 } completion:
	 ^(BOOL finished)
	 {
		 [weakSelf shakeWithShakes:14 andBlock:
		  ^()
		  {
			  [warning removeFromSuperview];
			  weakSelf.animating = false;
			  block();
		  }];
	 }];
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
//	NSLog(@"Picked attack #%li: %@", (long)sender.tag, self.attackChosen);
	
	[self reloadAttackTargets:NO];
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
		[self reloadAttackTargets:NO];
		[self switchToPanel:self.attackSelectPanelCord];
	}
}

- (IBAction)examineBackPress
{
	if (self.animating || self.uiAnimating)
		return;
	
	if (self.examinationCreature != nil)
	{
		//un-examine that creature
		self.examinationCreature = nil;
		[self reloadPanels];
		[self reloadAttackTargets:YES];
	}
	else
	{
		//go back to main
		[self switchToPanel:self.mainPanelCord];
		[self reloadAttackTargets:NO];
	}
}


- (IBAction)examineButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	
	[self reloadAttackTargets:YES];
	[self switchToPanel:self.examinePanelCord];
}


- (IBAction)craftButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	
	[self resetLastAttack];
	
	if (self.map.canCraft)
	{
		//open crafting menu
		self.examinationItem = nil;
		self.examineRecipies = self.map.preloadedCrafts;
		[self switchToPanel:self.inventoryPanelCord];
	}
}

- (IBAction)repeatButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	
	self.examinationCreature = nil;
	
	NSString *attack = self.lastAttack;
	Creature *target = self.lastTarget;
	[self resetLastAttack];
	
	//repeat the last attack
	[self.map.player useAttackWithName:attack onX:target.x andY:target.y];
	self.lastAttack = attack;
	self.lastTarget = target;
}


- (IBAction)attacksButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	
	[self resetLastAttack];
	
	self.attackPage = 0;
	[self switchToPanel:self.attackSelectPanelCord];
}

- (IBAction)defendButtonPress
{
    if (self.animating || self.uiAnimating)
        return;
    
    [self resetLastAttack];
    [self.map.player useAttackWithName:@"defend" onX:self.map.player.x andY:self.map.player.y];
}

-(void) breakDownItem
{
	//convert to materials, and put them in your inventory
	NSString *material = loadValueString(self.examinationItem.type == ItemTypeArmor ? @"Armors" : @"Implements", self.examinationItem.name, @"breaks into");
	[self.map addItem:[[Item alloc] initWithName:material andType:ItemTypeInventory]];
	
	[self.map saveInventory];
	
	[[SoundPlayer sharedPlayer] playSound:@"craft"];
	
	Tile *tile = self.map.tiles[self.map.player.y][self.map.player.x];
	tile.treasure = nil;
	tile.treasureType = TreasureTypeNone;
	tile.changed = true;
	[self.map.player breakStealth];
	[self updateTiles];
	[tile saveWithX:self.map.player.x andY:self.map.player.y];
	
	//end turn
	__weak typeof(self) weakSelf = self;
	[self switchToPanel:self.mainPanelCord withBlock:
	^()
	{
		[weakSelf.map update];
	}];
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
					
					[[SoundPlayer sharedPlayer] playSound:@"craft"];
					
					if (it.type != ItemTypeInventory)
					{
						Tile *tile = self.map.tiles[self.map.player.y][self.map.player.x];
						tile.treasureType = TreasureTypeBag;
						tile.treasure = it;
						tile.changed = true;
						[self updateTiles];
						[tile saveWithX:self.map.player.x andY:self.map.player.y];
					}
					else
						[self.map addItem:it];
					
					[self.map.player breakStealth];
					[self.map saveInventory];
					
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
					int healingAmount = (item.healing * self.map.player.metabolism) / 100;
					self.map.player.health = MIN(self.map.player.health + healingAmount, self.map.player.maxHealth);
					floatText = [NSString stringWithFormat:@"%i", healingAmount];
				}
				if (item.damageBuff > 0)
					self.map.player.damageBoosted += item.damageBuff;
				if (item.invisibilityBuff > 0)
					self.map.player.stealthed += item.invisibilityBuff;
				if (item.statusImmunityBuff > 0)
					self.map.player.immunityBoosted += item.statusImmunityBuff;
				if (item.timeBuff > 0)
					self.map.player.extraAction += item.timeBuff;
				if (item.skateBuff > 0)
					self.map.player.skating += item.skateBuff;
				if (item.defenseBuff > 0)
					self.map.player.defenseBoosted += item.defenseBuff;
				item.number -= 1;
				
				//unload crafts
				self.map.preloadedCrafts = nil;
				
				//remove the item if it's at 0
				if (item.number == 0)
					[self.map.inventory removeObject:item];
				
				[self.map saveInventory];
				
				//remake your sprite if necessary
				if (item.remakeSprite)
					[self regenerateCreatureSprite:self.map.player];
				
				[self.itemTable reloadData];
				
				__weak typeof(self) weakSelf = self;
				[self switchToPanel:self.mainPanelCord withBlock:
				^()
				{
					//make an item sound effect
					[[SoundPlayer sharedPlayer] playSound:@"heal"];
					
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
						[[SoundPlayer sharedPlayer] playSound:@"unlock"];
						
						self.map.player.hacks -= 1;
						tile.treasureType = TreasureTypeChest;
						tile.changed = true;
						[self.map.player breakStealth];
						[self reloadPanels];
						[self updateTiles];
					}
					return;
				}
				
				int slot = [self.map.player slotForItem:self.examinationItem];
				if (slot == -1)
					[self breakDownItem];
				else
				{
					//equip
					if (self.examinationItem.type == ItemTypeArmor)
					{
						Item *old = [[Item alloc] initWithName:self.map.player.armors[slot] andType:ItemTypeArmor];
						if (old.name.length > 0)
							tile.treasure = old;
						else
						{
							tile.treasureType = TreasureTypeNone;
							tile.changed = true;
							[self updateTiles];
							[tile saveWithX:self.map.player.x andY:self.map.player.y];
						}
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
					
					[self.map.player invalidateCache];
					[self.map.player breakStealth];
					
					//end turn
					__weak typeof(self) weakSelf = self;
					[self switchToPanel:self.mainPanelCord withBlock:
					^()
					{
						[weakSelf.map update];
					}];
				}
			}
			else if (sender.tag == 2)
			{
				//cancel
				[self switchToPanel:self.mainPanelCord];
			}
			else
			{
				//break down
				[self breakDownItem];
			}
			break;
		case ItemTypeInventory:
			if (sender.tag == 1)
			{
				//add that item to your inventory
				
				//stack the item if possible
				[self.map addItem:self.examinationItem];
				
				[self.map saveInventory];
				
				[self.map.player breakStealth];
				
				
				tile.changed = true;
				tile.treasureType = TreasureTypeNone;
				[tile saveWithX:self.map.player.x andY:self.map.player.y];
				
				[self updateTiles];
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
	
	[self resetLastAttack];
	
	if (self.map.inventory.count > 0)
	{
		//opens the inventory so you can use inventory buttons
		self.examinationItem = nil;
		self.examineRecipies = nil;
		[self switchToPanel:self.inventoryPanelCord];
	}
}


- (IBAction)pickUpButtonPress
{
	if (self.animating || self.uiAnimating)
		return;
	
	[self resetLastAttack];
	
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
		[self switchToPanel:self.inventoryPanelCord];
	}
}

-(void)resetLastAttack
{
	self.lastAttack = nil;
	self.lastTarget = nil;
	
	[self pullBackPanel];
}

-(void)pullBackPanel
{
	self.repeatPromptCord.constant = -self.repeatPromptPanel.frame.size.height;
	[self.view layoutIfNeeded];
}

-(void)tapGesture:(UITapGestureRecognizer *)sender
{
	if (self.animating || self.uiAnimating)
		return;
	
	[self resetLastAttack];
	
	CGPoint touchPoint = [sender locationInView:self.mapView];
	int x = ((int)floorf(touchPoint.x) - self.mapView.xOffset) / GAMEPLAY_TILE_SIZE;
	int y = ((int)floorf(touchPoint.y) - self.mapView.yOffset) / GAMEPLAY_TILE_SIZE;
	Tile *tile = self.map.tiles[y][x];

//	NSLog(@"touched (%i %i), player is at (%i %i)", x, y, self.map.player.x, self.map.player.y);
	
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
                self.aoeIndicatorX = x;
                self.aoeIndicatorY = y;
				[self reloadPanels];
			}
			else
			{
				if (self.aoeIndicatorView != nil)
				{
					[self.aoeIndicatorView removeFromSuperview];
					self.aoeIndicatorView = nil;
                    x = self.aoeIndicatorX;
                    y = self.aoeIndicatorY;
				}
				
				self.lastAttack = self.attackChosen;
				self.lastTarget = ((Tile *) self.map.tiles[y][x]).inhabitant;
				
				//use the attack
				[self.map.player useAttackWithName:self.attackChosen onX:x andY:y];
				
				//and switch the UI back
				self.attackChosen = nil;
				[self reloadAttackTargets:NO];
//				[self switchToPanel:self.mainPanelCord];
			}
		}
		return;
	}
	else if (self.activePanelCord == self.examinePanelCord)
	{
		//you are in examine view
		if (tile.targetLevel == TargetLevelInRange)
		{
			self.examinationCreature = tile.inhabitant;
			[self reloadPanels];
			[self reloadAttackTargets:YES];
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	//make everything invisible
	self.view.hidden = true;
	
	if ([segue.identifier isEqualToString:@"defeat"])
	{
		DefeatViewController *dvc = segue.destinationViewController;
		dvc.creature = self.map.player;
		dvc.message = self.defeatMessage;
	}
	else if ([segue.identifier isEqualToString:@"changeMap"])
	{
		ChangeMapViewController *change = segue.destinationViewController;
		[change loadMap:self.map];
	}
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
		itemCell.nameLabel.text = [NSString stringWithFormat:@"%@%@", item.name, item.number > 1 ? [NSString stringWithFormat:@" x%i", item.number] : @""];
	}
	else
	{
		NSString *recipie = self.examineRecipies[indexPath.row];
		NSMutableString *recipieDesc = [NSMutableString new];
		int aNum = loadValueNumber(@"Recipies", recipie, @"ingredient a amount").intValue;
		[recipieDesc appendFormat:@"%@%@", loadValueString(@"Recipies", recipie, @"ingredient a"), aNum > 1 ? [NSString stringWithFormat:@" x%i", aNum] : @""];
		if (loadValueBool(@"Recipies", recipie, @"ingredient b"))
		{
			int bNum = loadValueNumber(@"Recipies", recipie, @"ingredient b amount").intValue;
			[recipieDesc appendFormat:@" + %@%@", loadValueString(@"Recipies", recipie, @"ingredient b"), bNum > 1 ? [NSString stringWithFormat:@" x%i", bNum] : @""];
		}
		int rNum = loadValueNumber(@"Recipies", recipie, @"result amount").intValue;
		[recipieDesc appendFormat:@" -> %@%@", loadValueString(@"Recipies", recipie, @"result"), rNum > 1 ? [NSString stringWithFormat:@" x%i", rNum] : @""];
		itemCell.nameLabel.text = recipieDesc;
	}
	itemCell.nameLabel.textColor = loadColorFromName(@"ui text");
	return itemCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self reloadPanels];
}

@end
