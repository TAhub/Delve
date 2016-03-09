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

@interface CharacterCreatorViewController ()

@property (weak, nonatomic) IBOutlet UIView *characterView;
@property (weak, nonatomic) IBOutlet UIView *statsView;
@property (weak, nonatomic) IBOutlet UIView *interfaceContainer;

@property (weak, nonatomic) IBOutlet UIButton *raceButton;
@property (weak, nonatomic) IBOutlet UIButton *appearanceButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (strong, nonatomic) Creature *creature;
@property (strong, nonatomic) UIView *innerCreatureView;
@property int appearanceNumber;
@property int raceNumber;

-(NSString *)raceName;

@end

@implementation CharacterCreatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self formatPanel:self.characterView];
	[self formatPanel:self.statsView];
	[self formatPanel:self.interfaceContainer];
	
	[self formatButton:self.raceButton];
	[self formatButton:self.appearanceButton];
	[self formatButton:self.startButton];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	self.innerCreatureView = [UIView new];
	self.innerCreatureView.center = CGPointMake(self.characterView.frame.size.width / 2 - GAMEPLAY_TILE_SIZE / 2, self.characterView.frame.size.height / 2 - GAMEPLAY_TILE_SIZE / 2);
	[self.characterView addSubview:self.innerCreatureView];
	
	//TODO: save the last-generated character in a special user default, so you can try them again
	self.appearanceNumber = 0;
	self.raceNumber = 0;
	
	[self reloadCreature];
	[self reloadSprite];
	[self reloadLabels];
}

-(void)reloadCreature
{
	//TODO: set the skill trees with things the player picks
	self.creature = [[Creature alloc] initWithRace:self.raceName skillTrees:[NSArray arrayWithObjects:@"bow", @"conditioning", @"smithing", @"sacred light", @"wisdom", nil] andAppearanceNumber:self.appearanceNumber];
}



-(void)reloadLabels
{
	makeInfoLabelInView(self.creature, self.statsView);
	
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	GameViewController *gvc = segue.destinationViewController;
	[gvc loadGen:self.creature];
}

@end