//
//  Review.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/1/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "Review.h"

@implementation Review

@dynamic seller;
@dynamic reviewer;
@dynamic review;
@dynamic rating;
@dynamic title;
@dynamic itemDescription;

+ (nonnull NSString *)parseClassName {
    return @"Review";
}

@end
