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

@interface CharacterCreatorViewController ()

@property (weak, nonatomic) IBOutlet UIView *characterView;
@property (weak, nonatomic) IBOutlet UIView *statsView;
@property (weak, nonatomic) IBOutlet UIView *interfaceContainer;

@property (weak, nonatomic) IBOutlet UIButton *raceButton;
@property (weak, nonatomic) IBOutlet UIButton *appearanceButton;

@property (strong, nonatomic) Creature *creature;
@property (strong, nonatomic) UIView *innerCreatureView;

@end

@implementation CharacterCreatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self formatPanel:self.characterView];
	[self formatPanel:self.statsView];
	[self formatPanel:self.interfaceContainer];
	
	[self formatButton:self.raceButton];
	[self formatButton:self.appearanceButton];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.innerCreatureView = [UIView new];
	self.innerCreatureView.center = CGPointMake(self.characterView.frame.size.width / 2 - GAMEPLAY_TILE_SIZE / 2, self.characterView.frame.size.height / 2 - GAMEPLAY_TILE_SIZE / 2);
	[self.characterView addSubview:self.innerCreatureView];
	
	//TODO: save the last-generated character in a special user default, so you can try them again
	
	[self reloadCreature];
	[self reloadSprite];
	[self reloadLabels];
}

-(void)reloadCreature
{
	//TODO: set the creature's appearance and skill trees to the ones chosen by the user
	//this should probably be a custom initializer
	//maybe the initializer can even decode appearance numbers and detect the total number? I dunno
	self.creature = [[Creature alloc] initWithRace:@"human" skillTrees:[NSArray arrayWithObjects:@"bow", @"conditioning", @"smithing", @"sacred light", @"wisdom", nil] andAppearanceNumber:1];
}

-(void)reloadLabels
{
	makeInfoLabelInView(self.creature, self.statsView);
	
	//TODO: set button labels
	//the race button should have the current race
	//
	//the appearance button should have the current appearance number
	//which goes in an order like (hair 1, coloration 1, male), (hair 2, coloration 1, male), etc
}

-(void)reloadSprite
{
	makeCreatureSpriteInView(self.creature, self.innerCreatureView);
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
