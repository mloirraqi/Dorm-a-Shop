//
//  Review.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/1/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Parse/Parse.h>
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface Review : PFObject <PFSubclassing>

@property (nonatomic, strong) User *seller;
@property (nonatomic, strong) User *reviewer;
@property (nonatomic, strong) NSString *review;
@property (nonatomic, strong) NSNumber *rating;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *itemDescription;

@end

NS_ASSUME_NONNULL_END
