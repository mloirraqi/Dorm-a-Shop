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
    self.messageLabel.text = (NSString *) self.chat[@"text"];
    PFObject *senderObject = self.chat[@"sender"];
    self.profilePic.layer.cornerRadius = 20;
    self.profilePic.layer.masksToBounds = YES;
    
    if ([senderObject.objectId isEqualToString:PFUser.currentUser.objectId]) {
//        [self.profilePic removeConstraints:[self.profilePic constraints]];
        [self.messageLabel setTextAlignment:NSTextAlignmentRight];
        self.profilePicWidth.constant = 0;
        self.profilePic.hidden = YES;
    } else {
        self.profilePicWidth.constant = 40;
        self.profilePic.image = [UIImage imageWithData:self.imageFile];
        self.profilePic.hidden = NO;
        [self.messageLabel setTextAlignment:NSTextAlignmentLeft];
    }
    
    [self setNeedsLayout];
}

@end
