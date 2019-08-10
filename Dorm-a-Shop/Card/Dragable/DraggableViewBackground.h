//
//  DraggableViewBackground.h
//  RKSwipeCards
//
//  Created by Richard Kim on 8/23/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
// Modified 2019 by Mohamed Loirraqi, Ilana Shapiro, Addison Zhang

#import <UIKit/UIKit.h>
#import "DraggableView.h"

@interface DraggableViewBackground : UIView <DraggableViewDelegate>

- (void)cardSwipedLeft:(UIView *)card;
- (void)cardSwipedRight:(UIView *)card;

@end
