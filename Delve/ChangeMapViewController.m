//
//  ChangeMapViewController.m
//  Delve
//
//  Created by Theodore Abshire on 3/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "ChangeMapViewController.h"
#import "GameViewController.h"
#import "Map.h"
#import "Creature.h"

extern BOOL cachingEnabled;

@interface ChangeMapViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) Map *oldMap;
@property (strong, nonatomic) Map *nextMap;
@property int selected;

@property (weak, nonatomic) IBOutlet UITableView *levelTable;
@property (weak, nonatomic) IBOutlet UIButton *pickButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionText;
@property (weak, nonatomic) IBOutlet UIView *textPanel;
@property (weak, nonatomic) IBOutlet UIView *tablePanel;




@end

@implementation ChangeMapViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	cachingEnabled = false;
	
	[self formatButton:self.pickButton];
	[self formatPanel:self.textPanel];
	[self formatPanel:self.tablePanel];
	[self setInfoText:-1];
	
	[[NSUserDefaults standardUserDefaults] setObject:@"change" forKey:@"game phase"];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (self.oldMap == nil)
	{
		//this must be a loaded game then
		//so load the map, to generate a new map from
		[self loadMap:[[Map alloc] initFromSave]];
	}
	
	//recharge to remove all buffs, so your portrait isn't a weird color
	[self.oldMap.player recharge];
	
	self.levelTable.delegate = self;
	self.levelTable.dataSource = self;
	[self.levelTable reloadData];
}

- (IBAction)pressPickButton
{
	if (self.nextMap != nil)
	{
		int oldLevel = ((NSNumber *)self.oldMap.player.skillTreeLevels[self.selected]).intValue;
		if (oldLevel != 4)
		{
			self.oldMap.player.skillTreeLevels[self.selected] = @(oldLevel + 1);
			[self.oldMap.player recharge];
			[self performSegueWithIdentifier:@"changeMap" sender:self];
		}
	}
	else
		NSLog(@"Next map not ready!");
}

-(void)setInfoText:(int)on
{
	self.selected = on;
	if (on == -1)
	{
		[self.pickButton setTitleColor:loadColorFromName(@"ui text grey") forState:UIControlStateNormal];
		self.descriptionText.text = @"Pick a skill!";
	}
	else
	{
		NSString *tree = self.oldMap.player.skillTrees[on];
		int oldLevel = ((NSNumber *)self.oldMap.player.skillTreeLevels[on]).intValue;
		[self.pickButton setTitleColor:oldLevel == 4 ? loadColorFromName(@"ui text grey") : loadColorFromName(@"ui text") forState:UIControlStateNormal];
		[self.descriptionText setText:[self.oldMap.player treeDescription:tree atLevel:oldLevel]];
	}
}

-(void)loadMap:(Map *)map
{
	self.oldMap = map;
	
	//load new map in thread
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^() {
		self.nextMap = [[Map alloc] initWithMap:map];
	});
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	cachingEnabled = true;
	
	GameViewController *game = segue.destinationViewController;
	[game loadMap:self.nextMap];
}

#pragma tableview

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.oldMap.player.skillTrees.count;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *skillCell = [tableView dequeueReusableCellWithIdentifier:@"skillCell"];
	
	skillCell.textLabel.text = self.oldMap.player.skillTrees[indexPath.row];
	return skillCell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//set the info text
	[self setInfoText:(int)indexPath.row];
}

@end
