//
//  Watches.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/25/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Parse/Parse.h>

NS_ASSUME_NONNULL_BEGIN

@interface Watches : PFObject <PFSubclassing>

@property (nonatomic, strong) NSString *watchID;
@property (nonatomic, strong) PFObject *post;
@property (nonatomic, strong) PFObject *user;

@end

NS_ASSUME_NONNULL_END
