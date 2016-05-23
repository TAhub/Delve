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
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
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
	self.textLabel.textColor = loadColorFromName(@"ui text");
	
	self.pageOn = 0;
	
	[self formatPage];
}

-(void)formatPage
{
	//TODO: change the contents of the text label to contain the correct text, and the image to contain the right image
	
	//TODO: screen structure
	//all screenshots should be about as wide as the screen, but significantly narrower vertically
	//PAGE 0:
	//	a picture of the top bar (make a character with finesse, shield, and dodge, to explain the concept of those icons)
	//	text is an explanation of each row
	//PAGE 1:
	//	a screenshot of that sample character in a fight on the first floor
	//	text is a basic overview of combat
	//		dodges and blocks are resources that refill when not in a fight, or manually with dodge and other special moves
	//		some attacks cannot be blocked or dodged, as mentioned in their descriptions
	//		many moves have minimum or maximum range
	//		every attack has an element; some enemies may be resistant or weak to various elements
	//PAGE 2:
	//	a screenshot of a guardian on top of a teleport pad
	//	text is a simple statement of your goal and very barebones plot overview
	//		this series of caverns inhabited by the ancient Eol was recently re-discovered
	//		everyone wants to get to the bottom-most layer, where there is a functional Eol vessel (maybe super-quick faction overview if there's room)
	//		you were, for some reason or another, exiled; your only hope is to get past EVERYONE to get to the vessel
	//		get to the teleporter at the top of each floor to continue down
	
	
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
