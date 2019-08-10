//
//  CoreDataManager.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/1/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "User.h"
#import "Watches.h"
#import "ConversationCoreData+CoreDataClass.h"
#import "PostCoreData+CoreDataClass.h"
#import "UserCoreData+CoreDataClass.h"
#import "ConversationCoreData+CoreDataClass.h"
#import "ReviewCoreData+CoreDataClass.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataManager : NSObject

+ (id)shared;

- (NSMutableArray *)getActivePostsFromCoreData;
- (NSMutableArray *)getHotPostsFromCoreData;
- (NSMutableArray *)getActiveWatchedPostsForCurrentUserFromCoreData;
- (NSMutableArray *)getActivePostsFromCoreDataForUser:(UserCoreData *)user;
- (NSMutableArray *)getProfilePostsFromCoreDataForUser:(UserCoreData *)user;
- (NSManagedObject *)getCoreDataEntityWithName:(NSString *)name withObjectId:(NSString *)postObjectId withContext:(NSManagedObjectContext *)context;
- (NSMutableArray *)getAllUsersInRadiusFromCoreData;
- (NSMutableArray *)getAllConvosFromCoreData;
- (NSManagedObject *)getConvoFromCoreData:(NSString *)senderId;
- (NSMutableArray *)getSimilarPostsFromCoreData:(PostCoreData *)post;
- (NSMutableArray *)getReviewsFromCoreDataForSeller:(UserCoreData *)seller;

- (PostCoreData *)savePostToCoreDataWithObjectId:(NSString * _Nullable)postObjectId withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCreatedDate:(NSDate * _Nullable)createdAt withSoldStatus:(BOOL)sold withWatchStatus:(BOOL)watched withWatchObjectId:(NSString * _Nullable)watchObjectId withWatchCount:(long long)watchCount withHotness:(double)hotness withAuthor:(UserCoreData * _Nullable)author withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;
- (UserCoreData *)saveUserToCoreDataWithObjectId:(NSString * _Nullable)userObjectId withUsername:(NSString * _Nullable)username withLocation:(NSString * _Nullable)location withAddress:(NSString * _Nullable)address withProfilePic:(NSData * _Nullable)imageData inRadius:(BOOL)inRadius withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;
- (ConversationCoreData *)saveConversationToCoreDataWithObjectId:(NSString * _Nullable)conversationObjectId withDate:(NSDate *)updatedAt withSender:(UserCoreData * _Nullable)sender withLastText:(NSString * _Nullable)lastText withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;
- (ReviewCoreData *)saveReviewToCoreDataWithObjectId:(NSString * _Nullable)objectId withSeller:(UserCoreData * _Nullable)seller withReviewer:(UserCoreData * _Nullable)reviewer withRating:(int)rating withReview:(NSString * _Nullable)review withTitle:(NSString *)title withItemDescription:(NSString *)itemDescription withDate:(NSDate * _Nullable)date withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;

- (void)enqueueCoreDataBlock:(BOOL (^)(NSManagedObjectContext *context))block withName:(NSString *)name;
- (void)enqueueDoneSavingPostsWatches;
- (void)enqueueDoneSavingUsers;
- (void)enqueueDoneSavingConversations;
- (void)enqueueDoneSavingReviews;

@end

NS_ASSUME_NONNULL_END
