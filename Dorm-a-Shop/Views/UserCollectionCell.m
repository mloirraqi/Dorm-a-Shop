//
//  UserCollectionCell.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 08/07/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "UserCollectionCell.h"

@implementation UserCollectionCell {
    CGFloat profileRadius;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.profilePic.clipsToBounds = YES;
    self.profilePic.layer.masksToBounds = YES;
    self.profilePic.contentMode = UIViewContentModeScaleAspectFill;
    self.profilePic.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.profilePic.layer.borderWidth = 4.0f;
}

-(void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    profileRadius = self.profilePic.frame.size.height * 0.5;
    if (self.profilePic.layer.cornerRadius != profileRadius) {
        self.profilePic.layer.cornerRadius = profileRadius;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setUser {
    [self.profilePic setImage:[UIImage imageWithData:self.user.profilePic]];
    self.username.text = self.user.username;
    self.locationLabel.text = self.user.address;
}

@end
