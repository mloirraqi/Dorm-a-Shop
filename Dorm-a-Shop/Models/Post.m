//
//  Post.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "Post.h"
#import <Parse/Parse.h>

@implementation Post

@dynamic postID;
@dynamic author;
@dynamic caption;
@dynamic image;
@dynamic category;
@dynamic condition;
@dynamic price;
@dynamic title;
@dynamic sold;
@dynamic watch;
@dynamic watchCount;

+ (nonnull NSString *)parseClassName {
    return @"Post";
}

@end
