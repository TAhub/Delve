//
//  BlueViewController.m
//  Delve
//
//  Created by Theodore Abshire on 3/17/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "BlueViewController.h"

@interface BlueViewController ()

@end

@implementation BlueViewController

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self performSegueWithIdentifier:@"start" sender:self];
}

@end
