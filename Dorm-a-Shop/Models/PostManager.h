//
//  PostManager.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface PostManager : NSObject

+ (id)shared;

@property (nonatomic, strong) NSMutableArray *allPostsArray;
@property (nonatomic, strong) NSMutableArray *watchedPostsArray;

- (NSMutableArray *)getProfilePostsForUser:(PFUser *)user;
- (void)getWatchedPostsForCurrentUserWithCompletion:(void (^)(NSMutableArray *, NSError *))completion;
- (void)getAllPostsWithCompletion:(void (^)(NSMutableArray *, NSError *))completion;
- (void)unwatchPost:(Post *)post withCompletion:(void (^)(NSError *))completion;
- (void)watchPost:(Post *)post withCompletion:(void (^)(NSError *))completion;
- (void)setPost:(Post *)post sold:(BOOL)sold withCompletion:(void (^)(NSError *))completion;
- (void)postListing:(UIImage * _Nullable)image withCaption:(NSString * _Nullable)caption withPrice:(NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post *, NSError *))completion;
- (void)getCurrentUserWatchStatusForPost:(Post *)post withCompletion:(void (^)(Post *, NSError *))completion;

@end

NS_ASSUME_NONNULL_END
