//
//  CharacterServices.h
//  Delve
//
//  Created by Theodore Abshire on 3/8/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Creature;

void makeCreatureSpriteInView(Creature *cr, UIView *view);
void makeInfoLabelInView(Creature *cr, UIView *view, int countdown);