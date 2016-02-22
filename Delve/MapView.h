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

@end


@interface MapView : UIView

@property (weak, nonatomic) id<MapViewDelegate> delegate;

-(void)initializeMapAtX:(int)x andY:(int)y;

-(void)setPositionWithX:(int)x andY:(int)y;

@end
