//
//  OverlayView.m
//  RKSwipeCards
//
//  Created by Richard Kim on 5/22/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//

#import "OverlayView.h"

@implementation OverlayView
@synthesize imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"noButton"]];
        [self addSubview:imageView];
    }
    return self;
}

-(void)setMode:(GGOverlayViewMode)mode {
    if (_mode == mode) {
        return;
    }
    
    _mode = mode;
    
    if(mode == GGOverlayViewModeLeft) {
        imageView.image = [UIImage imageNamed:@"ic_cancel"];
    } else {
        imageView.image = [UIImage imageNamed:@"ic_accept"];
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    imageView.frame = CGRectMake((self.superview.frame.size.width/2 - 50), (self.superview.frame.size.height/2 - 50), 100, 100);
}


@end
