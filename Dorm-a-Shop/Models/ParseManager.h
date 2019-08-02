//
//  ParseManager.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/1/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "User.h"
#import "Review.h"
#import "ConversationCoreData+CoreDataClass.h"
#import "PostCoreData+CoreDataClass.h"
#import "UserCoreData+CoreDataClass.h"
#import "ConversationCoreData+CoreDataClass.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface ParseManager : NSObject

+ (id)shared;
@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) NSArray *conditions;
@property (nonatomic, strong) NSMutableArray *categoryCounts;
@property (nonatomic, strong) NSMutableArray *conditionCounts;
@property (nonatomic, strong) NSMutableArray *priceCounts;

- (void)queryAllPostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion;
- (void)queryWatchedPostsForUser:(PFUser * _Nullable)user withCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion;
- (void)queryWatchCountForPost:(Post *)post withCompletion:(void (^)(int, NSError *))completion;
- (void)queryAllUsersWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion;
- (void)queryReviewsForSeller:(User *)seller withCompletion:(void (^)(NSMutableArray *, NSError *))completion;
- (void)queryConversationsFromParseWithCompletion:(void (^)(NSMutableArray<ConversationCoreData *> *, NSError *))completion;

- (void)watchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion;
- (void)unwatchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion;
- (void)setPost:(PostCoreData *)postCoreData sold:(BOOL)sold withCompletion:(void (^)(NSError *))completion;

- (void)postListingToParseWithImage:(UIImage * _Nullable)image withCaption:(NSString * _Nullable)caption withPrice:(NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post * _Nullable, NSError * _Nullable))completion;
- (PFFileObject *)getPFFileFromImage:(UIImage * _Nullable)image;
- (void)postReviewToParseWithSeller:(User * _Nullable)seller withRating:(NSNumber * _Nullable)rating withReview:(NSString * _Nullable)review withCompletion:(void (^)(Review * _Nullable, NSError * _Nullable))completion;

- (void)viewPost:(PostCoreData *)postCoreData;
- (void)queryViewedPostswithCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
