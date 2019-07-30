//
//  UserCell.h
//  Dorm-a-Shop
//
//  Created by addisonz on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserCoreData+CoreDataClass.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface UserCell : UITableViewCell

@property (strong, nonatomic) UserCoreData *user;
@property (strong, nonatomic) PFObject *convo;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *recentText;
- (void)setUser;

@end

NS_ASSUME_NONNULL_END
