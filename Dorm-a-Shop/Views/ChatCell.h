//
//  ChatCell.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface ChatCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) PFObject *chat;
- (void)showMsg;

@end

NS_ASSUME_NONNULL_END
