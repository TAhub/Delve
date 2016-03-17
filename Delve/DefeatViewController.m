//
//  DefeatViewController.m
//  Delve
//
//  Created by Theodore Abshire on 3/17/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "DefeatViewController.h"
#import "CharacterServices.h"
#import "Constants.h"
#import "Creature.h"

@interface DefeatViewController ()

@property (weak, nonatomic) IBOutlet UILabel *defeatLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIView *creatureView;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;

@property (weak, nonatomic) IBOutlet UIView *creaturePanel;
@property (weak, nonatomic) IBOutlet UIView *contentPanel;




@end

@implementation DefeatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	
	//TODO: this is probably pretty dumb given the name but
	//this same screen should also be used as a victory screen
	//with a short description of how you turned on the ship, what happens next is up to you, whatever
	
	

	[self formatPanel:self.creaturePanel];
	[self formatPanel:self.contentPanel];

	[self formatButton:self.returnButton];
	
	self.messageLabel.text = self.message;
	self.messageLabel.textColor = loadColorFromName(@"ui text");
	self.defeatLabel.textColor = loadColorFromName(@"ui text");
	
	self.creature.health = 1;
	makeCreatureSpriteInView(self.creature, self.creatureView);
}

@end
