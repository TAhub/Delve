//
//  CharacterCreatorViewController.m
//  Delve
//
//  Created by Theodore Abshire on 3/8/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "CharacterCreatorViewController.h"
#import "CharacterServices.h"
#import "Constants.h"

@interface CharacterCreatorViewController ()

@property (weak, nonatomic) IBOutlet UIView *characterView;
@property (weak, nonatomic) IBOutlet UIView *statsView;
@property (weak, nonatomic) IBOutlet UIView *interfaceContainer;

@property (weak, nonatomic) IBOutlet UIButton *raceButton;
@property (weak, nonatomic) IBOutlet UIButton *appearanceButton;



@end

@implementation CharacterCreatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self formatPanel:self.characterView];
	[self formatPanel:self.statsView];
	[self formatPanel:self.interfaceContainer];
	
	[self formatButton:self.raceButton];
	[self formatButton:self.appearanceButton];
	
	//TODO: save the last-generated character in a special user default, so you can try them again
	
	//TODO: format the contents of the buttons and panels
	//
	//the stats view should contain the same contents as the stats info area in the main game
	//using makeInfoLabelInView()
	//
	//the character view should contain a character image view of the character
	//using makeCreatureSpriteInView()
	//
	//the race button should have the current race
	//
	//the appearance button should have the current appearance number
	//which goes in an order like (hair 1, coloration 1, male), (hair 2, coloration 1, male), etc
}

- (IBAction)pressButton:(UIButton *)sender
{
	switch(sender.tag)
	{
		case 0: //race
			//TODO: cycle between player races
			break;
		case 1: //appearance
			//TODO: cycle between possible appearances
			break;
	}
}


@end
