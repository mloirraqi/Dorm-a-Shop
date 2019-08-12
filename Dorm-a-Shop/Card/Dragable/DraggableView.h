//
//  DraggableView.h
//  RKSwipeCards
//
//  Created by Richard Kim on 5/21/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "OverlayView.h"
#import "Card.h"

@protocol DraggableViewDelegate <NSObject>

-(void)cardSwipedLeft:(UIView *)card;
-(void)cardSwipedRight:(UIView *)card;

@end

@interface DraggableView : UIView

@property (weak) id <DraggableViewDelegate> delegate;

@property (nonatomic, strong)UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic)CGPoint originalPoint;
@property (nonatomic,strong)OverlayView* overlayView;
@property (nonatomic, strong) Card* card;

-(void)leftClickAction;
-(void)rightClickAction;
- (id)initWithFrame:(CGRect)frame card:(Card *)card;

@end
