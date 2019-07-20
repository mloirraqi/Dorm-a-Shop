//
//  PostManager.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "PostManager.h"
#import "Post.h"
@import Parse;

@implementation PostManager

@synthesize allPostsArray;

#pragma mark Singleton Methods

+ (instancetype)shared {
    static PostManager *sharedPostManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPostManager = [[self alloc] init];
    });
    return sharedPostManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        PFQuery *postQuery = [Post query];
        [postQuery orderByDescending:@"createdAt"];
        [postQuery includeKey:@"author"];
        [postQuery whereKey:@"sold" equalTo:[NSNumber numberWithBool: NO]];
        
        __weak PostManager *weakSelf = self;
        [postQuery findObjectsInBackgroundWithBlock:^(NSArray<Post *> * _Nullable posts, NSError * _Nullable error) {
            if (posts) {
                weakSelf.allPostsArray = [NSMutableArray arrayWithArray:posts];
            } else {
                NSLog(@"😫😫😫 Error getting posts from database: %@", error.localizedDescription);
            }
        }];
    }
    return self;
}

@end
