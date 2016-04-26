//
//  ScoresViewController.m
//  Delve
//
//  Created by Theodore Abshire on 4/25/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "ScoresViewController.h"
#import "Constants.h"
#import "ItemTableViewCell.h"

@interface ScoresViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *labelPanel;
@property (weak, nonatomic) IBOutlet UIView *tablePanel;
@property (weak, nonatomic) IBOutlet UIView *returnPanel;

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;

@property (strong, nonatomic) NSArray *scores;

@end

@implementation ScoresViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	[self formatButton:self.returnButton];
	[self formatPanel:self.labelPanel];
	[self formatPanel:self.tablePanel];
	[self formatPanel:self.returnPanel];
	self.label.textColor = loadColorFromName(@"ui text");
	
	[self.table registerNib:[UINib nibWithNibName:@"ItemCell" bundle:nil] forCellReuseIdentifier:@"itemCell"];
	self.table.delegate = self;
	self.table.dataSource = self;
	
	self.scores = [[NSUserDefaults standardUserDefaults] objectForKey:@"scores"];
	if (self.scores == nil)
		self.scores = [NSArray new];
}

- (IBAction)pressReturnButton
{
	[self performSegueWithIdentifier:@"return" sender:self];
}

#pragma mark: table view delegate and datasource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.scores.count == 0 ? 1 : self.scores.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ItemTableViewCell *itemCell = [tableView dequeueReusableCellWithIdentifier:@"itemCell"];
	
	itemCell.nameLabel.textColor = loadColorFromName(@"ui text");
	
	if (self.scores.count == 0)
		itemCell.nameLabel.text = @"Nothing yet!";
	else
		itemCell.nameLabel.text = self.scores[indexPath.row];
	
	return itemCell;
}

@end
