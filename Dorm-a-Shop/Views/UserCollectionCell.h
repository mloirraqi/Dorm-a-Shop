//
//  UserCollectionCell.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 08/07/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserCoreData+CoreDataClass.h"
#import "ConversationCoreData+CoreDataClass.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface UserCollectionCell : UICollectionViewCell

@property (strong, nonatomic) UserCoreData *user;
@property (strong, nonatomic) PFUser *pfuser;
@property (strong, nonatomic) ConversationCoreData *convo;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

- (void)setUser;

@end
NS_ASSUME_NONNULL_END
