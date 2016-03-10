//
//  CharacterCreatorViewController.m
//  Delve
//
//  Created by Theodore Abshire on 3/8/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "CharacterCreatorViewController.h"
#import "CharacterServices.h"
#import "Creature.h"
#import "Constants.h"
#import "GameViewController.h"
#import "TreeCollectionViewCell.h"

@interface CharacterCreatorViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *characterView;
@property (weak, nonatomic) IBOutlet UIView *statsView;
@property (weak, nonatomic) IBOutlet UIView *interfaceContainer;

@property (weak, nonatomic) IBOutlet UIButton *raceButton;
@property (weak, nonatomic) IBOutlet UIButton *appearanceButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (weak, nonatomic) IBOutlet UICollectionView *treeCollection;
@property (weak, nonatomic) IBOutlet UILabel *skillLabel;


@property (strong, nonatomic) NSArray *preloadedTrees;


@property (strong, nonatomic) Creature *creature;
@property (strong, nonatomic) UIView *innerCreatureView;
@property int appearanceNumber;
@property int raceNumber;
@property (strong, nonatomic) NSMutableArray *skills;

-(NSString *)raceName;

@end

@implementation CharacterCreatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//preload the skill trees by type
	NSDictionary *trees = loadEntries(@"SkillTrees");
	self.preloadedTrees = [NSArray arrayWithObjects:[NSMutableArray new], [NSMutableArray new], [NSMutableArray new], [NSMutableArray new], nil];
	for (int i = 0; i < 4; i++)
	{
		NSString *type = [self skillTreeWithNumber:i];
		NSMutableArray *array = self.preloadedTrees[i];
		for (NSString *key in trees.allKeys)
			if ([type isEqualToString:loadValueString(@"SkillTrees", key, @"type")])
				[array addObject:key];
	}
	
	
	[self formatPanel:self.characterView];
	[self formatPanel:self.statsView];
	[self formatPanel:self.interfaceContainer];
	
	[self formatButton:self.raceButton];
	[self formatButton:self.appearanceButton];
	[self formatButton:self.startButton];
	
	self.treeCollection.delegate = self;
	self.treeCollection.dataSource = self;
	
	
	//TODO: convert the collection view into a table view, with sections
	//and add a label that counts the number of attacks and of what type (IE look at every skill that's at "", and see what the slot type is)
	//TODO: remember to remove the tree collection view cell when I do
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.innerCreatureView = [UIView new];
	self.innerCreatureView.center = CGPointMake(self.characterView.frame.size.width / 2 - GAMEPLAY_TILE_SIZE / 2, self.characterView.frame.size.height / 2 - GAMEPLAY_TILE_SIZE / 2);
	[self.characterView addSubview:self.innerCreatureView];
	
	self.skillLabel.text = @"Pick a skill to turn it on or off.";
	
	//TODO: save the last-generated character in a special user default, so you can try them again
	
	self.skills = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", nil];
	self.appearanceNumber = 0;
	self.raceNumber = 0;
	
	[self reloadCreature];
	[self reloadSprite];
	[self reloadLabels];
}

-(void)reloadCreature
{
	//TODO: set the skill trees with things the player picks
	self.creature = [[Creature alloc] initWithRace:self.raceName skillTrees:self.skills andAppearanceNumber:self.appearanceNumber];
}

-(void)reloadLabels
{
	makeInfoLabelInView(self.creature, self.statsView);
	
	[self.startButton setTitleColor:[self shouldPerformSegueWithIdentifier:@"" sender:nil] ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
	
	//set button labels
	[self.raceButton setTitle:self.raceName forState:UIControlStateNormal];
	[self.appearanceButton setTitle:[NSString stringWithFormat:@"Appearance #%i", self.appearanceNumber + 1] forState:UIControlStateNormal];
}

-(NSString *)raceName
{
	switch (self.raceNumber)
	{
		case 0: return @"human";
		case 1: return @"eoling";
		case 2: return @"highborn";
		case 3: return @"raider";
		default: return @"human";
	}
}

-(void)reloadSprite
{
	makeCreatureSpriteInView(self.creature, self.innerCreatureView);
}

- (IBAction)pressButton:(UIButton *)sender
{
	switch(sender.tag)
	{
		case 0:
			//cycle between player races
			self.raceNumber = (self.raceNumber + 1) % 4;
			self.appearanceNumber = 0;
			self.skills = [NSMutableArray arrayWithObjects:@"", @"", @"", @"", @"", nil];
			break;
		case 1:
			//cycle between possible appearances
			self.appearanceNumber = (self.appearanceNumber + 1) % self.creature.maxAppearanceNumber;
			break;
	}
	[self reloadCreature];
	[self reloadLabels];
	[self reloadSprite];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
	for (int i = 0; i < 5; i++)
		if (((NSString *)self.skills[i]).length == 0)
			return false;
	return true;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	GameViewController *gvc = segue.destinationViewController;
	[gvc loadGen:self.creature];
}

#pragma mark collection view

-(NSString *)skillTreeWithNumber:(int)number
{
	switch(number)
	{
		case 0: return @"body";
		case 1: return @"war";
		case 2: return @"sacred";
		case 3: return @"ritual";
		default: return @"invalid";
	}
}

-(int)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 4;
}
-(int)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	NSArray *type = self.preloadedTrees[section];
	return type.count;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	TreeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"skillCell" forIndexPath:indexPath];
	
	BOOL contains = false;
	NSArray *type = self.preloadedTrees[indexPath.section];
	NSString *key = type[indexPath.row];
	
	for (int i = 0; i < 5; i++)
		if ([self.skills[i] isEqualToString:key])
		{
			//you have it!
			contains = true;
			break;
		}
	
	cell.backgroundColor = contains ? [UIColor redColor] : [UIColor blueColor];
	
	cell.label.text = key;
	
	return cell;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
	NSArray *slots = loadValueArray(@"Races", self.raceName, @"skill slot types");
	NSArray *type = self.preloadedTrees[indexPath.section];
	NSString *key = type[indexPath.row];
	
	//select that skill
	BOOL contains = false;
	for (int i = 0; i < 5; i++)
		if ([self.skills[i] isEqualToString:key])
		{
			//you had it!
			contains = true;
			self.skills[i] = @"";
			break;
		}
	if (!contains)
		for (int i = 0; i < 5; i++)
			if ([self.skills[i] isEqualToString:@""])
				if ([slots[i] isEqualToString:@"wildcard"] || [slots[i] isEqualToString:loadValueString(@"SkillTrees", key, @"type")])
				{
					self.skills[i] = key;
					break;
				}
	
	[collectionView reloadData];
	self.skillLabel.text = [self.creature treeDescription:key atLevel:1];
	[self reloadCreature];
	[self reloadLabels];
}

@end