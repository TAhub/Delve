//
//  DefeatViewController.h
//  Delve
//
//  Created by Theodore Abshire on 3/17/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "FormattingViewController.h"

@class Creature;

@interface DefeatViewController : FormattingViewController

@property (strong, nonatomic) NSString *message;
@property (strong, nonatomic) Creature *creature;

@end
