//
//  PostManager.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "PostCoreData+CoreDataProperties.h"
#import "UserCoreData+CoreDataProperties.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface PostManager : NSObject

+ (id)shared;

//@property (nonatomic, strong) NSMutableArray *allPostsArray;
//@property (nonatomic, strong) NSMutableArray *watchedPostsArray;

- (void)queryActivePostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion;
- (NSMutableArray *)getActivePostsFromCoreData;
- (void)queryWatchedPostsForUser:(PFUser * _Nullable)user withCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion;

- (NSMutableArray *)getActiveWatchedPostsForCurrentUserFromCoreData;
- (void)queryWatchCountForPost:(Post *)post withCompletion:(void (^)(int, NSError *))completion;
- (NSMutableArray *)getProfilePostsFromCoreDataForUser:(UserCoreData *)user;
- (NSManagedObject *)getCoreDataEntityWithName:(NSString *)name withObjectId:(NSString *)postObjectId withContext:(NSManagedObjectContext *)context;

- (void)watchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion;
- (void)unwatchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion;
- (void)setPost:(PostCoreData *)postCoreData sold:(BOOL)sold withCompletion:(void (^)(NSError *))completion;

- (void)postListingToParseWithImage:(UIImage * _Nullable)image withCaption:(NSString * _Nullable)caption withPrice:(NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post *, NSError *))completion;
+ (PFFileObject *)getPFFileFromImage:(UIImage * _Nullable)image;

- (PostCoreData *)savePostToCoreDataWithObjectId:(NSString *)postObjectId withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCreatedDate:(NSDate *)createdAt withSoldStatus:(BOOL)sold withWatchStatus:(BOOL)watched withWatchObjectId:(NSString *)watchObjectId withWatchCount:(long long)watchCount withManagedObjectContext:(NSManagedObjectContext*)context;
- (UserCoreData *)saveUserToCoreDataWithObjectId:(NSString *)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withProfilePic:(NSData * _Nullable)imageData withManagedObjectContext:(NSManagedObjectContext*)context;


@end

NS_ASSUME_NONNULL_END
