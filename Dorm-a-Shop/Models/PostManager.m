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

@interface PostManager ()

@end

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

- (NSMutableArray *)getProfilePostsForUser:(PFUser *)user {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(Post *post, NSDictionary *bindings) {
        return [((PFObject *)post[@"author"]).objectId isEqualToString:user.objectId];
    }];
    return [NSMutableArray arrayWithArray:[self.allPostsArray filteredArrayUsingPredicate:predicate]];
}

- (void)getWatchedPostsForCurrentUserWithCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    if (self.watchedPostsArray != nil) {
        completion(self.watchedPostsArray, nil);
    } else {
        PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
        [watchQuery orderByDescending:@"createdAt"];
        [watchQuery whereKey:@"user" equalTo:[PFUser currentUser]];
        [watchQuery includeKey:@"post"];
        
        __weak PostManager *weakSelf = self;
        [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable userWatches, NSError * _Nullable error) {
            if (error) {
                NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
                completion(nil, error);
            } else {
                weakSelf.watchedPostsArray = [[NSMutableArray alloc] init];
                for (PFObject *watch in userWatches) {
                    Post *watchedPost = watch[@"post"];
                    [weakSelf.watchedPostsArray addObject:watchedPost];
                }
                
                completion(weakSelf.watchedPostsArray, nil);
            }
        }];
    }
}

- (void)getCurrentUserWatchStatusForPost:(Post *)post withCompletion:(void (^)(Post *, NSError *))completion {
//    if (post.watchCount != nil) {
//        NSLog(@"watch count is: %@", post.watchCount);
//        completion(post, nil);
//    } else {
        PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
        [watchQuery orderByDescending:@"createdAt"];
        [watchQuery whereKey:@"post" equalTo:post];

        [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable postWatches, NSError * _Nullable error) {
            if (error) {
                completion(nil, error);
            } else {
                post.watchCount = [NSNumber numberWithUnsignedInteger:postWatches.count];
                if (postWatches.count > 0) {
                    bool watched = NO;
                    for (PFObject *watch in postWatches) {
                        if ([((PFObject *)watch[@"user"]).objectId isEqualToString:[PFUser currentUser].objectId]) {
                            post.watch = watch;
                            watched = YES;
                            break;
                        }
                    }
                    if (!watched) {
                        post.watch = nil;
                    }
                } else {
                    post.watch = nil;
                }
                completion(post, nil);
            }
        }];
    //}
}

- (void)getAllPostsWithCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    if (self.allPostsArray != nil) {
        completion(self.allPostsArray, nil);
    } else {
        PFQuery *postQuery = [Post query];
        [postQuery orderByDescending:@"createdAt"];
        [postQuery includeKey:@"author"];
        
        __weak PostManager *weakSelf = self;
        [postQuery findObjectsInBackgroundWithBlock:^(NSArray<Post *> * _Nullable posts, NSError * _Nullable error) {
            if (posts) {
                weakSelf.allPostsArray = [NSMutableArray arrayWithArray:posts];
                NSLog(@"all posts array: %@", weakSelf.allPostsArray);
                completion(weakSelf.allPostsArray, nil);
            } else {
                NSLog(@"😫😫😫 Error getting posts from database: %@", error.localizedDescription);
                completion(nil, error);
            }
        }];
    }
}

- (void)unwatchPost:(Post *)post withCompletion:(void (^)(NSError *))completion {
    __weak PostManager *weakSelf = self;
    [post.watch deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            post.watch = nil;
            int watchCountInt = [post.watchCount intValue];
            watchCountInt --;
            post.watchCount = [NSNumber numberWithInt:watchCountInt];
            [weakSelf.watchedPostsArray removeObject:post];
            completion(nil);
        } else {
            completion(error);
        }
    }];
}

- (void)watchPost:(Post *)post withCompletion:(void (^)(NSError *))completion {
    PFObject *watch = [PFObject objectWithClassName:@"Watches"];
    watch[@"post"] = post;
    watch[@"user"] = [PFUser currentUser];
    
    __weak PostManager *weakSelf = self;
    [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            post.watch = watch;
            int watchCountInt = [post.watchCount intValue];
            watchCountInt ++;
            post.watchCount = [NSNumber numberWithInt:watchCountInt];
            NSLog(@"%@", post.watchCount);
            [weakSelf.watchedPostsArray addObject:post];
            completion(nil);
        } else {
            completion(error);
        }
    }];
}

- (void)setPost:(Post *)post sold:(BOOL)sold withCompletion:(void (^)(NSError *))completion {
    post.sold = sold;
    
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            NSLog(@"Post status update failed: %@", error.localizedDescription);
            completion(error);
        } else {
            completion(nil);
        }
    }];
}

- (void)submitNewPost:(Post *)post withCompletion:(void (^)(NSError *))completion {
    __weak PostManager *weakSelf = self;
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            NSLog(@"Post status update failed: %@", error.localizedDescription);
            [weakSelf.allPostsArray insertObject:post atIndex:0];
            completion(error);
        } else {
            completion(nil);
        }
    }];
}

- (void)postListing:(UIImage * _Nullable)image withCaption:(NSString * _Nullable)caption withPrice:(NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post *, NSError *))completion {
    Post *newPost = [Post new];
    newPost.image = [PostManager getPFFileFromImage:image];
    newPost.author = [PFUser currentUser];
    newPost.caption = caption;
    newPost.condition = condition;
    newPost.category = category;
    newPost.title = title;
    newPost.sold = NO;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *priceNum = [formatter numberFromString:price];
    newPost.price = priceNum;
    
    __weak PostManager *weakSelf = self;
    [newPost saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            completion(nil, error);
        } else {
            [weakSelf.allPostsArray insertObject:newPost atIndex:0];
            completion(newPost, nil);
        }
    }];
}

+ (PFFileObject *)getPFFileFromImage: (UIImage * _Nullable)image {
    if (!image) {
        return nil;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    if (!imageData) {
        return nil;
    }
    return [PFFileObject fileObjectWithName:@"image.png" data:imageData];
}

@end
