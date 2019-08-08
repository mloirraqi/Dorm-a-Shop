//
//  CoreDataManager.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/1/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "NSNotificationCenter+MainThread.h"

@interface CoreDataManager ()

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSOperationQueue *persistentContainerQueue;

@end

@implementation CoreDataManager

#pragma mark Singleton Methods

+ (instancetype)shared {
    static CoreDataManager *sharedCoreDataManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCoreDataManager = [[self alloc] init];
    });
    return sharedCoreDataManager;
}

- (instancetype) init {
    self = [super init];
    self.appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = self.appDelegate.persistentContainer.viewContext;
    self.persistentContainerQueue = [[NSOperationQueue alloc] init];
    self.persistentContainerQueue.maxConcurrentOperationCount = 1;
    return self;
}

- (NSMutableArray *)getActivePostsFromCoreData {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:self.context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"sold == %@", [NSNumber numberWithBool:NO]]];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray __block *mutableResults = [NSMutableArray arrayWithArray:results];
    if (results.count > 1) {
        double initialRank = ((PostCoreData *)results[0]).rank;
        double rank = initialRank;
        
        for (PostCoreData *result in results) {
            if (rank != result.rank) {
                break;
            }
        }
        
        NSArray *sortedPosts = [mutableResults sortedArrayUsingComparator:^NSComparisonResult(id firstObj, id secondObj) {
            PostCoreData *firstPost = (PostCoreData *)firstObj;
            PostCoreData *secondPost = (PostCoreData *)secondObj;
            
            if (firstPost.rank > secondPost.rank) {
                return NSOrderedAscending;
            } else if (firstPost.rank > secondPost.rank) {
                return NSOrderedDescending;
            } else if ([firstPost.createdAt compare:secondPost.createdAt] == NSOrderedDescending) {
                return NSOrderedDescending;
            } else if ([firstPost.createdAt compare:secondPost.createdAt] == NSOrderedAscending) {
                return NSOrderedAscending;
            }
            
            return NSOrderedSame;
        }];
        
        mutableResults = [NSMutableArray arrayWithArray:sortedPosts];
    }
    
    return mutableResults; //firstObject is nil if results has length 0
}

- (NSMutableArray *)getActiveWatchedPostsForCurrentUserFromCoreData {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:self.context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"(watched == %@) AND (sold == %@)", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]]];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

- (NSMutableArray *)getProfilePostsFromCoreDataForUser:(UserCoreData *)user {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:self.context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"author.objectId == %@", user.objectId]];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    [request setReturnsObjectsAsFaults:NO];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects for current user: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

- (NSManagedObject *)getCoreDataEntityWithName:(NSString *)name withObjectId:(NSString *)postObjectId withContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:name];
    [request setPredicate:[NSPredicate predicateWithFormat:@"objectId == %@", postObjectId]];
    [request setFetchLimit:1];
    [request setReturnsObjectsAsFaults:NO];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    return [results firstObject]; //firstObject is nil if results has length 0
}

- (NSMutableArray *)getAllUsersInRadiusFromCoreData {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"UserCoreData" inManagedObjectContext:self.context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"inRadius == YES"]];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

- (NSMutableArray *)getAllConvosFromCoreData {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ConversationCoreData" inManagedObjectContext:self.context];
    [request setEntity:entityDescription];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    [request setReturnsObjectsAsFaults:NO];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updatedAt" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

- (NSManagedObject *)getConvoFromCoreData:(NSString *)senderId {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ConversationCoreData" ];
    [request setPredicate:[NSPredicate predicateWithFormat:@"sender.objectId == %@", senderId]];
    [request setFetchLimit:1];
    [request setReturnsObjectsAsFaults:NO];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching ConversationCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    return [results firstObject];
}

- (NSMutableArray *)getReviewsFromCoreDataForSeller:(UserCoreData *)seller {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ReviewCoreData"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"seller.objectId == %@", seller.objectId]];
    [request setReturnsObjectsAsFaults:NO];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching ReviewCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateWritten" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

- (NSMutableArray *)getSimilarPostsFromCoreData:(PostCoreData *)post {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:self.context];
    if([post.condition isEqualToString:@"Other"]) {
         [request setPredicate:[NSPredicate predicateWithFormat:@"((caption CONTAINS[cd] %@) OR (title CONTAINS[cd] %@)) AND (objectId != %@)", post.title, post.title, post.objectId]];
    } else {
         [request setPredicate:[NSPredicate predicateWithFormat:@"(((caption CONTAINS[cd] %@) OR (title CONTAINS[cd] %@)) OR (category == %@)) AND (objectId != %@)", post.title, post.title, post.category, post.objectId]];
    }
    [request setEntity:entityDescription];
    
    NSError *error = nil;
    NSArray *results = [self.context executeFetchRequest:request error:&error];
    [request setReturnsObjectsAsFaults:NO];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    return [NSMutableArray arrayWithArray:results];
}

- (PostCoreData *)savePostToCoreDataWithObjectId:(NSString * _Nullable)postObjectId withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCreatedDate:(NSDate * _Nullable)createdAt withSoldStatus:(BOOL)sold withWatchStatus:(BOOL)watched withWatchObjectId:(NSString * _Nullable)watchObjectId withWatchCount:(long long)watchCount withHotness:(double)hotness withAuthor:(UserCoreData * _Nullable)author withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    PostCoreData *postCoreData;
    
    //a new post upload naturally won't immediately have an objectId until it is saved in Parse, so we don't check to see if it already exists bc in this case the user is just creating it
    if (postObjectId) {
        postCoreData = (PostCoreData *)[self getCoreDataEntityWithName:@"PostCoreData" withObjectId:postObjectId withContext:context];
    }
    
    //if post doesn't already exist in core data, then create it
    if (!postCoreData) {
        postCoreData = (PostCoreData *)[NSEntityDescription insertNewObjectForEntityForName:@"PostCoreData" inManagedObjectContext:context];
        postCoreData.author = author;
        
        //the author has to exist to set its associated post. author should exist, it should have been set during signup. this is just to ensure it exists
        if (author && !author.post) {
            author.post = [[NSSet alloc] initWithObjects:postCoreData, nil];
        } else if (author) {
            author.post = [author.post setByAddingObject:postCoreData];
        }
        
        postCoreData.image = imageData;
        postCoreData.caption = caption;
        postCoreData.condition = condition;
        postCoreData.category = category;
        postCoreData.title = title;
        postCoreData.sold = sold;
        postCoreData.watched = watched;
        postCoreData.watchCount = watchCount;
        postCoreData.price = price;
        postCoreData.createdAt = createdAt;
        postCoreData.watchObjectId = watchObjectId;
        postCoreData.objectId = postObjectId;
        postCoreData.viewed = NO;
        postCoreData.hotness = hotness;
        
        __weak CoreDataManager *weakSelf = self;
        [self enqueueCoreDataBlock:^(NSManagedObjectContext *context) {
            PostCoreData *postData;
            BOOL operationAlreadyExists = NO;

            if (postObjectId) {
                postData = (PostCoreData *)[weakSelf getCoreDataEntityWithName:@"PostCoreData" withObjectId:postObjectId withContext:context];
                operationAlreadyExists = [self queueContainsOperationWithName:postObjectId];
            }

            if (postData || operationAlreadyExists) {
                return NO;
            }

            return YES;
        } withName:[NSString stringWithFormat:@"%@", postCoreData.objectId]];
//        [self saveContext];
    }
    
    return postCoreData;
}

- (UserCoreData *)saveUserToCoreDataWithObjectId:(NSString * _Nullable)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withAddress:(NSString * _Nullable)address withProfilePic:(NSData * _Nullable)imageData inRadius:(BOOL)inRadius withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    UserCoreData *userCoreData;
    if (userObjectId) {
        userCoreData = (UserCoreData *)[self getCoreDataEntityWithName:@"UserCoreData" withObjectId:userObjectId withContext:context];
    }
    
    //if post doesn't already exist in core data, then create it
    if (!userCoreData) {
        userCoreData = (UserCoreData *)[NSEntityDescription insertNewObjectForEntityForName:@"UserCoreData" inManagedObjectContext:context];
        
        userCoreData.objectId = userObjectId;
        userCoreData.profilePic = imageData;
        userCoreData.email = email;
        userCoreData.location = location;
        userCoreData.username = username;
        userCoreData.address = address;
        userCoreData.inRadius = inRadius;
        
        __weak CoreDataManager *weakSelf = self;
        [self enqueueCoreDataBlock:^(NSManagedObjectContext *context) {
            UserCoreData *userData;
            BOOL operationAlreadyExists = NO;

            if (userObjectId) {
                userData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:userObjectId withContext:context];
                operationAlreadyExists = YES;
            }

            if (userData || operationAlreadyExists) {
                return NO;
            }

            return YES;
        } withName:[NSString stringWithFormat:@"%@", userCoreData.objectId]];
//        [self saveContext];
    }
    
    return userCoreData;
}

- (ConversationCoreData *)saveConversationToCoreDataWithObjectId:(NSString * _Nullable)conversationObjectId withDate:(NSDate *)updatedAt withSender:(UserCoreData * _Nullable)sender withLastText:(NSString * _Nullable)lastText withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    ConversationCoreData *conversationCoreData;
    if (conversationObjectId) {
        conversationCoreData = (ConversationCoreData *)[self getCoreDataEntityWithName:@"ConversationCoreData" withObjectId:conversationObjectId withContext:context];
    }
    
    if (!conversationCoreData) {
        conversationCoreData = (ConversationCoreData *)[NSEntityDescription insertNewObjectForEntityForName:@"ConversationCoreData" inManagedObjectContext:context];
        conversationCoreData.objectId = conversationObjectId;
        conversationCoreData.sender = sender;
        conversationCoreData.lastText = lastText;
        conversationCoreData.updatedAt = updatedAt;
        
        __weak CoreDataManager *weakSelf = self;
        [self enqueueCoreDataBlock:^(NSManagedObjectContext *context) {
            ConversationCoreData *conversationData;
            BOOL operationAlreadyExists = NO;

            if (conversationObjectId) {
                conversationData = (ConversationCoreData *)[weakSelf getCoreDataEntityWithName:@"ConversationCoreData" withObjectId:conversationObjectId withContext:context];
                operationAlreadyExists = [self queueContainsOperationWithName:conversationObjectId];
            }

            if (conversationData || operationAlreadyExists) {
                return NO;
            }

            return YES;
        } withName:[NSString stringWithFormat:@"%@", conversationCoreData.objectId]];
    }
//    [self saveContext];
    
    return conversationCoreData;
}

- (ReviewCoreData *)saveReviewToCoreDataWithObjectId:(NSString * _Nullable)objectId withSeller:(UserCoreData * _Nullable)seller withReviewer:(UserCoreData * _Nullable)reviewer withRating:(int)rating withReview:(NSString * _Nullable)review withTitle:(NSString *)title withItemDescription:(NSString *)itemDescription withDate:(NSDate * _Nullable)date withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    ReviewCoreData *reviewCoreData;
    if (objectId) {
        reviewCoreData = (ReviewCoreData *)[self getCoreDataEntityWithName:@"ReviewCoreData" withObjectId:objectId withContext:self.context];
    }
    
    if (!reviewCoreData) {
        reviewCoreData = (ReviewCoreData *)[NSEntityDescription insertNewObjectForEntityForName:@"ReviewCoreData" inManagedObjectContext:context];
        reviewCoreData.objectId = objectId;
        reviewCoreData.seller = seller;
        reviewCoreData.rating = rating;
        reviewCoreData.review = review;
        reviewCoreData.dateWritten = date;
        reviewCoreData.reviewer = reviewer;
        reviewCoreData.itemDescription = itemDescription;
        reviewCoreData.title = title;
        
        __weak CoreDataManager *weakSelf = self;
        [self enqueueCoreDataBlock:^(NSManagedObjectContext *context) {
            ReviewCoreData *reviewData;
            BOOL operationAlreadyExists = NO;
            if (objectId) {
                reviewData = (ReviewCoreData *)[weakSelf getCoreDataEntityWithName:@"ReviewCoreData" withObjectId:objectId withContext:weakSelf.context];
                operationAlreadyExists = [self queueContainsOperationWithName:objectId];
            }

            if (reviewData || operationAlreadyExists) {
                return NO;
            }

            return YES;
        } withName:[NSString stringWithFormat:@"%@", reviewCoreData.objectId]];
//        [self saveContext];
    }
    return reviewCoreData;
}

- (void)enqueueCoreDataBlock:(BOOL (^)(NSManagedObjectContext *context))block withName:(NSString *)name {
    BOOL (^blockCopy)(NSManagedObjectContext *) = [block copy];
    __weak CoreDataManager *weakSelf = self;
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        [weakSelf.context performBlockAndWait:^{
            BOOL okToSave = blockCopy(weakSelf.context);
            if (okToSave) {
                NSError *error = nil;
                if ([weakSelf.context save:&error] == NO) {
                    NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
                }
            }
        }];
    }];
    op.name = name;
    [self.persistentContainerQueue addOperation:op];
}

- (void)enqueueDoneSavingPostsWatches {
    [self.persistentContainerQueue addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DoneSavingPostsWatches" object:self userInfo:nil];
    }];
}

- (void)enqueueDoneSavingUsers {
    [self.persistentContainerQueue addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DoneSavingUsers" object:self userInfo:nil];
    }];
}

- (void)enqueueDoneSavingConversations {
    [self.persistentContainerQueue addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DoneSavingConversations" object:self userInfo:nil];
    }];
}

- (void)enqueueDoneSavingReviews {
    [self.persistentContainerQueue addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DoneSavingReviews" object:self userInfo:nil];
    }];
}

- (BOOL)queueContainsOperationWithName:(NSString *)name {
    for (NSOperation *operation in self.persistentContainerQueue.operations) {
        if ([operation.name isEqualToString:name]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)saveContext {
    NSError *error = nil;
    if ([self.context hasChanges] && ![self.context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
