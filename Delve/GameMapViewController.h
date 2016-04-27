//
//  GameMapViewController.h
//  Delve
//
//  Created by Theodore Abshire on 4/26/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import "FormattingViewController.h"

@class Map;
@class Creature;
@class MapView;

@interface GameMapViewController : FormattingViewController

-(void)loadMap:(Map *)map;
-(void)loadGen:(Creature *)genPlayer;
-(void)loadSave;

@property (strong, nonatomic) Map* map;

@property (strong, nonatomic) NSString *attackChosen;
@property BOOL animating;
@property BOOL uiAnimating;
@property (strong, nonatomic) NSString *defeatMessage;

@property (weak, nonatomic) IBOutlet UIView *creatureView;
@property (weak, nonatomic) IBOutlet MapView *mapView;

-(void)regenerateCreatureSprite:(Creature *)cr;
-(void)recalculateHidden;
-(void)moveCreatureAnim;
-(void)updateTiles;
-(void)updateCreature:(Creature *)cr;
-(void)fadeScreenInTime:(float)time withBlock:(void (^)(void))block;
-(void)shakeWithShakes:(int)shakes andBlock:(void (^)(void))block;
-(void)moveCreature:(Creature *)creature fromX:(int)x fromY:(int)y withBlock:(void (^)(void))block;
-(void)defeat:(NSString *)message;
-(void)goToNextMap;

@end
