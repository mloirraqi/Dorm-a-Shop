//
//  Watch.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Parse/Parse.h>
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface Watch : PFObject <PFSubclassing>

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PFUser *user;

@end

NS_ASSUME_NONNULL_END
