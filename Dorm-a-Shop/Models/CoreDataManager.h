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
#import "ConversationCoreData+CoreDataClass.h"
#import "PostCoreData+CoreDataClass.h"
#import "UserCoreData+CoreDataClass.h"
#import "ConversationCoreData+CoreDataClass.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataManager : NSObject

+ (id)shared;

- (NSMutableArray *)getActivePostsFromCoreData;
- (NSMutableArray *)getActiveWatchedPostsForCurrentUserFromCoreData;
- (NSMutableArray *)getProfilePostsFromCoreDataForUser:(UserCoreData *)user;
- (NSManagedObject *)getCoreDataEntityWithName:(NSString *)name withObjectId:(NSString *)postObjectId withContext:(NSManagedObjectContext *)context;
- (NSMutableArray *)getAllUsersFromCoreData;
- (NSMutableArray *)getAllConvosFromCoreData;
- (NSManagedObject *)getConvoFromCoreData:(NSString *)senderId;

- (PostCoreData *)savePostToCoreDataWithPost:(Post * _Nullable)post withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCreatedDate:(NSDate * _Nullable)createdAt withSoldStatus:(BOOL)sold withWatchStatus:(BOOL)watched withWatch:(Watches * _Nullable)watch withWatchCount:(long long)watchCount withAuthor:(UserCoreData * _Nullable)author withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;
- (UserCoreData *)saveUserToCoreDataWithObjectId:(NSString * _Nullable)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withAddress:(NSString * _Nullable)address withProfilePic:(NSData * _Nullable)imageData withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;
- (ConversationCoreData *)saveConversationToCoreDataWithObjectId:(NSString * _Nullable)conversationObjectId withDate:(NSDate *)updatedAt withSender:(UserCoreData * _Nullable)sender withLastText:(NSString * _Nullable)lastText withManagedObjectContext:(NSManagedObjectContext * _Nullable)context;
@end

NS_ASSUME_NONNULL_END
