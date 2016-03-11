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
#import "ItemTableViewCell.h"

@interface CharacterCreatorViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *characterView;
@property (weak, nonatomic) IBOutlet UIView *statsView;
@property (weak, nonatomic) IBOutlet UIView *interfaceContainer;

@property (weak, nonatomic) IBOutlet UIButton *raceButton;
@property (weak, nonatomic) IBOutlet UIButton *appearanceButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;


@property (weak, nonatomic) IBOutlet UILabel *skillLabel;


@property (strong, nonatomic) NSArray *preloadedTrees;


@property (weak, nonatomic) IBOutlet UITableView *treeTable;
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
	
	self.treeTable.delegate = self;
	self.treeTable.dataSource = self;
	
	
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
	
	self.skills = [NSMutableArray arrayWithObjects:@"dagger", @"reflexes", @"shield", @"strength", @"conditioning", nil];
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
	
	//set the skill label
	int body = 0;
	int war = 0;
	int ritual = 0;
	int sacred = 0;
	int wild = 0;
	NSArray *slots = loadValueArray(@"Races", self.raceName, @"skill slot types");
	for (int i = 0; i < self.skills.count; i++)
		if ([self.skills[i] isEqualToString:@""])
		{
			if ([slots[i] isEqualToString:@"body"])
				body += 1;
			else if ([slots[i] isEqualToString:@"war"])
				war += 1;
			else if ([slots[i] isEqualToString:@"ritual"])
				ritual += 1;
			else if ([slots[i] isEqualToString:@"sacred"])
				sacred += 1;
			else
				wild += 1;
		}
	NSMutableArray *sA = [NSMutableArray new];
	if (war > 0)
		[sA addObject:[NSString stringWithFormat:@"%i war", war]];
	if (sacred > 0)
		[sA addObject:[NSString stringWithFormat:@"%i sacred", sacred]];
	if (ritual > 0)
		[sA addObject:[NSString stringWithFormat:@"%i ritual", ritual]];
	if (body > 0)
		[sA addObject:[NSString stringWithFormat:@"%i body", body]];
	if (wild > 0)
		[sA addObject:[NSString stringWithFormat:@"%i wildcard", wild]];
	if (sA.count == 0)
		[sA addObject:@"None! Good to go!"];
	self.skillLabel.text = [NSString stringWithFormat:@"Open slots: %@", [sA componentsJoinedByString:@", "]];
	self.skillLabel.textColor = loadColorFromName(@"ui text");
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

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [self skillTreeWithNumber:section];
}

-(int)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSArray *type = self.preloadedTrees[section];
	return type.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"skillCell" forIndexPath:indexPath];
	
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
	
	cell.textLabel.text = key;
	cell.textLabel.textColor = contains ? loadColorFromName(@"ui text") : loadColorFromName(@"ui text grey");
	
	return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *slots = loadValueArray(@"Races", self.raceName, @"skill slot types");
	NSArray *type = self.preloadedTrees[indexPath.section];
	NSString *key = type[indexPath.row];
	
	NSString *alertText = @"";
	void (^alertBlock)(UIAlertAction *action) = nil;
	
	//select that skill
	BOOL contains = false;
	for (int i = 0; i < 5; i++)
		if ([self.skills[i] isEqualToString:key])
		{
			//you had it!
			contains = true;
			self.skills[i] = @"";
			[tableView reloadData];
			[self reloadCreature];
			[self reloadLabels];
			return;
		}
	if (!contains)
		for (int i = 0; i < 5; i++)
			if ([self.skills[i] isEqualToString:@""])
				if ([slots[i] isEqualToString:@"wildcard"] || [slots[i] isEqualToString:loadValueString(@"SkillTrees", key, @"type")])
				{
					//make the alert
					__weak typeof(self) weakSelf = self;
					alertText = [self.creature treeDescription:key atLevel:0];
					alertBlock =
					^(UIAlertAction *action)
					{
						weakSelf.skills[i] = key;
						[tableView reloadData];
						[weakSelf reloadCreature];
						[weakSelf reloadLabels];
					};
					break;
				}
	
	if (alertText.length > 0)
	{
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Pick skill?" message:alertText preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:alertBlock];
		[alert addAction:ok];
		
		UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:
		^(UIAlertAction *action)
		{
			[tableView reloadData];
		}];
		[alert addAction:cancel];
		
		[self presentViewController:alert animated:YES completion:nil];
	}
	else
		[tableView reloadData];
}

@end