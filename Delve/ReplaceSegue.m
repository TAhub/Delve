//
//  ReplaceSegue.m
//  Delve
//
//  Created by Theodore Abshire on 3/2/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "ReplaceSegue.h"

@implementation ReplaceSegue

-(void)perform
{
	UIViewController *source = (UIViewController *)[self sourceViewController];
	UIViewController *destination = (UIViewController *)[self destinationViewController];
	UINavigationController *nav = source.navigationController;
	[nav popToRootViewControllerAnimated:NO];
	[nav pushViewController:destination animated:YES];
}

@end
