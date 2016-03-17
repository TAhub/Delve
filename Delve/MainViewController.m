//
//  MainViewController.m
//  Delve
//
//  Created by Theodore Abshire on 3/17/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "MainViewController.h"
#import "Constants.h"
//#import "ChangeMapViewController.h"
#import "GameViewController.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIView *titlePanel;
@property (weak, nonatomic) IBOutlet UIView *contentPanel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *loadButton;




@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self formatButton:self.startButton];
	[self formatButton:self.loadButton];
	self.titleLabel.textColor = loadColorFromName(@"ui text");
	[self formatPanel:self.titlePanel];
	[self formatPanel:self.contentPanel];
}

- (IBAction)startButtonPressed
{
	[self performSegueWithIdentifier:@"newGame" sender:self];
}

- (IBAction)loadButtonPressed
{
	if (self.phase != nil)
	{
		if ([self.phase isEqualToString:@"game"])
			[self performSegueWithIdentifier:@"loadGame" sender:self];
		else if ([self.phase isEqualToString:@"change"])
			[self performSegueWithIdentifier:@"loadBetween" sender:self];
		else
			NSLog(@"Unknown phase %@!", self.phase);
	}
}

-(NSString *)phase
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"game phase"];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"loadGame"])
	{
		GameViewController *gvc = segue.destinationViewController;
		[gvc loadSave];
	}
//	else if ([segue.identifier isEqualToString:@"loadBetween"])
//	{
//		ChangeMapViewController *cmvc = segue.destinationViewController;
//	}
}

@end
