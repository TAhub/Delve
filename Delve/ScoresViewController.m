//
//  ScoresViewController.m
//  Delve
//
//  Created by Theodore Abshire on 4/25/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "ScoresViewController.h"
#import "Constants.h"

@interface ScoresViewController ()

@property (weak, nonatomic) IBOutlet UIView *labelPanel;
@property (weak, nonatomic) IBOutlet UIView *tablePanel;
@property (weak, nonatomic) IBOutlet UIView *returnPanel;

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;



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
}

- (IBAction)pressReturnButton
{
	[self performSegueWithIdentifier:@"return" sender:self];
}



@end
