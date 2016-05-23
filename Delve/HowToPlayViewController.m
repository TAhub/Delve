//
//  HowToPlayViewController.m
//  Delve
//
//  Created by Theodore Abshire on 5/20/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "HowToPlayViewController.h"
#import "Constants.h"

@interface HowToPlayViewController ()

@property (weak, nonatomic) IBOutlet UIView *titlePanel;
@property (weak, nonatomic) IBOutlet UIView *textPanel;
@property (weak, nonatomic) IBOutlet UIView *returnPanel;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *pageTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property int pageOn;

@end

@implementation HowToPlayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self formatButton:self.returnButton];
	[self formatButton:self.previousButton];
	[self formatButton:self.nextButton];
	[self formatPanel:self.titlePanel];
	[self formatPanel:self.textPanel];
	[self formatPanel:self.returnPanel];
	self.titleLabel.textColor = loadColorFromName(@"ui text");
	self.textView.textColor = loadColorFromName(@"ui text");
	self.pageTitleLabel.textColor = loadColorFromName(@"ui text");
	
	//give the image a black border
	[self.imageView.layer setBorderWidth: 3.0];
	[self.imageView.layer setBorderColor:[UIColor blackColor].CGColor];
	
	self.pageOn = 0;
	
	[self formatPage];
}

-(void)formatPage
{
	switch(self.pageOn)
	{
		case 0:
			self.pageTitleLabel.text = @"Top Bar";
			self.imageView.image = [UIImage imageNamed:@"illustrationTopbar.png"];
			self.textView.text = @"The first row is, left to right, your health, blue icons representing your blocks, green icons representing your dodges, and yellow icons representing your hacks.\n\nThe second row is icons representing your elemental resistances.\n\nThe third row is, left to right, your damage, your bonus normal-attack-only damage, your bonus healing item power, and the rounds left in this floor until you die.";
			break;
		case 1:
			self.pageTitleLabel.text = @"Combat Notes";
			self.imageView.image = [UIImage imageNamed:@"illustrationCombat.png"];
			self.textView.text = @"Dodges and blocks are resources that are depleted as you dodge or block attacks. They refill between fights, or when using some special moves (such as defend).\n\nEach attack has an element; examine enemies to see what elements they are weak to.\n\nKeep in mind that most ranged attacks have minimum ranges, and most powerful attacks have long cooldowns and/or ammo costs.";
			break;
		case 2:
			self.pageTitleLabel.text = @"Goal";
			self.imageView.image = [UIImage imageNamed:@"illustrationGoal.png"];
			self.textView.text = @"The ancient Path of the Eol has recently re-opened. Every faction in the world wants to control the prize at the end, a functional Eol vessel.\nYou are, for one reason or another, exiled. Your only hope is to find the vessel for yourself.\nYou'll have to fight (or run) past every single person in your way.\n\nTo continue down the path, locate the teleporter in the north-most end of the floor and defeat it's guardian.\nBut be warned, the ancient defenses of the Path are re-activating, and each floor has a time limit before it is cleansed!";
			break;
	}
	
	
	//hide buttons to keep you from going off of the text
	self.previousButton.hidden = self.pageOn == 0;
	self.nextButton.hidden = self.pageOn == 2;
}

- (IBAction)previousPress
{
	if (self.pageOn > 0)
	{
		self.pageOn -= 1;
		[self formatPage];
	}
}

- (IBAction)nextPress
{
	if (self.pageOn < 2)
	{
		self.pageOn += 1;
		[self formatPage];
	}
}



@end
