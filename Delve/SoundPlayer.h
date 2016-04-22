//
//  SoundPlayer.h
//  Delve
//
//  Created by Theodore Abshire on 4/21/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SoundPlayer : NSObject

+(id)sharedPlayer;
-(void) playSound:(NSString *)soundCategoryName;

@end