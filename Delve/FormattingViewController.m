//
//  FormattingViewController.m
//  Delve
//
//  Created by Theodore Abshire on 3/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "FormattingViewController.h"
#import "Constants.h"

@interface FormattingViewController ()

@end

@implementation FormattingViewController

-(void)viewDidLoad
{
	[super viewDidLoad];
	
	//TODO: set background color from the color list, maybe?
}

-(void)formatButton:(UIButton *)button
{
	button.layer.backgroundColor = loadColorFromName(@"ui text button").CGColor;
	button.layer.borderColor = button.layer.backgroundColor;
	button.layer.cornerRadius = 5.0;
	[button setTitleColor:loadColorFromName(@"ui text") forState:UIControlStateNormal];
}

-(void)formatPanel:(UIView *)panel
{
	//	panel.layer.borderWidth = .0;
	//	panel.layer.borderColor = panel.backgroundColor.CGColor;
	panel.layer.cornerRadius = 5.0;
}

@end
