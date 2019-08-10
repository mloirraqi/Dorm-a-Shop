//
//  Card.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 07/24/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "Card.h"

@implementation Card

- (instancetype)initWithUser:(UserCoreData *)user postsArray:(NSMutableArray *)postsArray {
    self = [super init];
    self.author = user;
    self.posts = postsArray;
    return self;
}

@end
