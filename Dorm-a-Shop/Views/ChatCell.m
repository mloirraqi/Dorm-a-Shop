//
//  ChatCell.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "ChatCell.h"

@implementation ChatCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.messageLabel.layer.cornerRadius = 5;
    self.messageLabel.layer.borderWidth = 0.5;
    self.messageLabel.layer.borderColor = UIColor.lightGrayColor.CGColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)showMsg {
    self.profilePic.layer.cornerRadius = 20;
    self.profilePic.layer.masksToBounds = YES;
    PFFileObject *imageFile = self.sender[@"ProfilePic"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:imageData];
            [self.profilePic setImage:image];
        }
    }];
    if (self.sender == [PFUser currentUser]) {
        [self.messageLabel setTextAlignment:NSTextAlignmentRight];
        self.profilePic.hidden = YES;
        [self.profilePic removeConstraints:[self.profilePic constraints]];
    }
    self.messageLabel.text = self.chat[@"text"];
}

@end
