//
//  UserCell.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "UserCell.h"

@implementation UserCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setUser {
    self.profilePic.layer.cornerRadius = 25;
    self.profilePic.layer.masksToBounds = YES;
    [self.profilePic setImage:[UIImage imageWithData:self.user.profilePic]];

    self.username.text = self.user.username;
    self.locationLabel.text = self.user.location;
    self.recentText.text = self.convo.lastText;
}

@end
