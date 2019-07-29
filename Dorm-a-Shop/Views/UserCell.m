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
    PFFileObject *imageFile = self.user[@"ProfilePic"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:imageData];
            [self.profilePic setImage:image];
        }
    }];
    self.username.text = self.user[@"username"];
    self.recentText.text = self.convo[@"lastText"];
}

@end
