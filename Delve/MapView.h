//
//  MapView.h
//  Delve
//
//  Created by Theodore Abshire on 2/22/16.
//  Copyright © 2016 Theodore Abshire. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MapViewDelegate

-(UIView *)viewAtTileWithX:(int)x andY:(int)y;
-(int)mapWidth;
-(int)mapHeight;

@end


@interface MapView : UIView

@property (weak, nonatomic) id<MapViewDelegate> delegate;

-(void)initializeMapAtX:(float)x andY:(float)y;
-(void)setPositionWithX:(float)x andY:(float)y withAnimBlock:(void (^)(void))animBlock andCompleteBlock:(void (^)(void))completeBlock;
-(void)remake;

-(int)xOffset;
-(int)yOffset;

-(BOOL)isPointOnscreenWithX:(int)x andY:(int)y;

@end
