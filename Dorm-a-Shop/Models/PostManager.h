//
//  PostManager.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "User.h"
#import "ConversationCoreData+CoreDataClass.h"
#import "PostCoreData+CoreDataClass.h"
#import "UserCoreData+CoreDataClass.h"
#import "ConversationCoreData+CoreDataClass.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface PostManager : NSObject

+ (id)shared;

//@property (nonatomic, strong) NSMutableArray *allPostsArray;
//@property (nonatomic, strong) NSMutableArray *watchedPostsArray;

- (void)queryAllPostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion;
- (NSMutableArray *)getActivePostsFromCoreData;
- (void)queryWatchedPostsForUser:(PFUser * _Nullable)user withCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion;

- (NSMutableArray *)getActiveWatchedPostsForCurrentUserFromCoreData;
- (void)queryWatchCountForPost:(Post *)post withCompletion:(void (^)(int, NSError *))completion;
- (NSMutableArray *)getProfilePostsFromCoreDataForUser:(UserCoreData *)user;
- (NSManagedObject *)getCoreDataEntityWithName:(NSString *)name withObjectId:(NSString *)postObjectId withContext:(NSManagedObjectContext *)context;
- (NSMutableArray *)getAllUsersFromCoreData;

- (void)queryAllUsersWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion;

- (void)watchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion;
- (void)unwatchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion;
- (void)setPost:(PostCoreData *)postCoreData sold:(BOOL)sold withCompletion:(void (^)(NSError *))completion;

- (void)postListingToParseWithImage:(UIImage * _Nullable)image withCaption:(NSString * _Nullable)caption withPrice:(NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post *, NSError *))completion;
+ (PFFileObject *)getPFFileFromImage:(UIImage * _Nullable)image;

- (PostCoreData *)savePostToCoreDataWithObjectId:(NSString * _Nullable)postObjectId withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCreatedDate:(NSDate * _Nullable)createdAt withSoldStatus:(BOOL)sold withWatchStatus:(BOOL)watched withWatchObjectId:(NSString * _Nullable)watchObjectId withWatchCount:(long long)watchCount withAuthor:(UserCoreData * _Nullable)author withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;
- (UserCoreData *)saveUserToCoreDataWithObjectId:(NSString * _Nullable)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withProfilePic:(NSData * _Nullable)imageData withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;

- (ConversationCoreData *)saveConversationToCoreDataWithObjectId:(NSString * _Nullable)conversationObjectId withSender:(UserCoreData * _Nullable)sender withLastText:(NSString * _Nullable)lastText withPfuser:(PFUser *)pfuser withPFconvo:(PFObject *)convo withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;
- (void)queryConversationsFromParseWithCompletion:(void (^)(NSMutableArray<ConversationCoreData *> *, NSError *))completion;


@end

NS_ASSUME_NONNULL_END
