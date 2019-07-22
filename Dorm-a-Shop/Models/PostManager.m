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

//- (instancetype)init {
//    self = [super init];
//    if (self) {
//        self.allPostsArray = [[NSMutableArray alloc] init];
//    }
//}

- (NSMutableArray *)getProfilePostsForUser:(PFUser *)user {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(Post *post, NSDictionary *bindings) {
        return [((PFObject *)post[@"author"]).objectId isEqualToString:user.objectId];
    }];
    return [NSMutableArray arrayWithArray:[self.allPostsArray filteredArrayUsingPredicate:predicate]];
}

- (void)getWatchedPostsForCurrentUserWithCompletion:(void (^)(NSMutableArray *, NSError *))completion{
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
                [weakSelf.watchedPostsArray addObject:watch[@"post"]];
            }
            completion(self.watchedPostsArray, nil);
        }
    }];
}

//- (void)getCurrentUserWatchStatusForPost:(Post *)post withCompletion:(void (^)(Post *, NSError *))completion {
//    PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
//    [watchQuery orderByDescending:@"createdAt"];
//    [watchQuery whereKey:@"post" equalTo:post];
//
//    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable postWatches, NSError * _Nullable error) {
//        if (error) {
//            completion(nil, error);
//        } else {
//            post.watchCount = postWatches.count;
//            if (post.watchCount > 0) {
//                bool watched = NO;
//                for (PFObject *watch in postWatches) {
//                    if ([((PFObject *)watch[@"user"]).objectId isEqualToString:[PFUser currentUser].objectId]) {
//                        post.watch = watch;
//                        watched = YES;
//                        break;
//                    }
//                }
//                if (!watched) {
//                    post.watch = nil;
//                }
//            } else {
//                post.watch = nil;
//            }
//            completion(post, nil);
//        }
//    }];
//}

- (void)getAllPostsWithCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    PFQuery *postQuery = [Post query];
    [postQuery orderByDescending:@"createdAt"];
    [postQuery includeKey:@"author"];
    [postQuery whereKey:@"sold" equalTo:[NSNumber numberWithBool: NO]];
    
    __weak PostManager *weakSelf = self;
    [postQuery findObjectsInBackgroundWithBlock:^(NSArray<Post *> * _Nullable posts, NSError * _Nullable error) {
        if (posts) {
            weakSelf.allPostsArray = [NSMutableArray arrayWithArray:posts];
            completion(weakSelf.allPostsArray, nil);
        } else {
            NSLog(@"😫😫😫 Error getting posts from database: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
}

- (void)unwatchPost:(Post *)post withCompletion:(void (^)(NSError *))completion {
    [post.watch deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            post.watch = nil;
            post.watchCount --;
            [self.watchedPostsArray removeObject:post];
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
    
    [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            post.watch = watch;
            post.watchCount ++;
            [self.watchedPostsArray addObject:post];
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
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            NSLog(@"Post status update failed: %@", error.localizedDescription);
            [self.allPostsArray insertObject:post atIndex:0];
            completion(error);
        } else {
            completion(nil);
        }
    }];
}

- (void)postListing: (UIImage * _Nullable)image withCaption: (NSString * _Nullable)caption withPrice: (NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post *, NSError *))completion {
    Post *newPost = [Post new];
    newPost.image = [self getPFFileFromImage:image];
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
    
    [newPost saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            NSLog(@"Post status update failed: %@", error.localizedDescription);
            [self.allPostsArray insertObject:newPost atIndex:0];
            completion(nil, error);
        } else {
            completion(newPost, nil);
        }
    }];
}

- (PFFileObject *)getPFFileFromImage: (UIImage * _Nullable)image {
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
