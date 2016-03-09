//
//  GameViewController.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "FormattingViewController.h"

@class Map;
@class Creature;

@interface GameViewController : FormattingViewController

-(void)loadMap:(Map *)map;
-(void)loadGen:(Creature *)genPlayer;

@end