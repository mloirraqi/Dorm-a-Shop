//
//  PostsManager.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "PostsManager.h"

@implementation PostsManager

@synthesize allPostsArray;

#pragma mark Singleton Methods

+ (instancetype)shared {
    static PostsManager *sharedPostsManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPostsManager = [[self alloc] init];
    });
    return sharedPostsManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        allPostsArray = [[NSArray alloc] init];
    }
    return self;
}

- (instancetype)initWithArray:(NSArray *)array {
    self = [super init];
    if (self) {
        allPostsArray = array;
    }
    return self;
}

@end
