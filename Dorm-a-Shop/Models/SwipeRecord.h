//
//  SwipeRecord.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/8/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Parse/Parse.h>
#import "User.h"
NS_ASSUME_NONNULL_BEGIN

@interface SwipeRecord : PFObject

@property (nonatomic, strong) User *user1;
@property (nonatomic, strong) User *user2;

@end

NS_ASSUME_NONNULL_END
