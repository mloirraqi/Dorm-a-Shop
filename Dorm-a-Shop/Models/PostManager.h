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

- (NSMutableArray *)getProfilePostsFromCoreDataForUser:(UserCoreData *)user;
- (void)queryWatchedPostsForCurrentUserWithCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion;
- (NSMutableArray *)getActiveWatchedPostsForCurrentUserFromCoreData;
//- (BOOL)getCurrentUserWatchStatusFromCoreDataForPost:(PostCoreData *)post;
- (void)queryWatchCountForPost:(Post *)post withCompletion:(void (^)(int, NSError *))completion;
- (void)queryActivePostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion;
- (NSMutableArray *)getActivePostsFromCoreData;
- (void)unwatchPost:(Post *)post withCompletion:(void (^)(NSError *))completion ;
- (void)watchPost:(Post *)post withCompletion:(void (^)(NSError *))completion;
- (void)setPost:(Post *)post sold:(BOOL)sold withCompletion:(void (^)(NSError *))completion;
- (void)postListing:(UIImage * _Nullable)image withCaption:(NSString * _Nullable)caption withPrice:(NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post *, NSError *))completion;
+ (PFFileObject *)getPFFileFromImage: (UIImage * _Nullable)image;
- (PostCoreData *)savePostWithObjectId:(NSString *)postObjectId withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title toCoreDataWithManagedObjectContext:(NSManagedObjectContext*)context;
- (UserCoreData *)saveUserWithObjectId:(NSString *)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withProfilePic:(NSData * _Nullable)imageData toCoreDataWithManagedObjectContext:(NSManagedObjectContext*)context;
- (NSManagedObject *)getCoreDataEntityWithName:(NSString *)name withObjectId:(NSString *)postObjectId withContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
