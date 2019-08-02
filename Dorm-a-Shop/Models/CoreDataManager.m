//
//  CoreDataManager.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/1/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "CoreDataManager.h"
#import "AppDelegate.h"

@interface CoreDataManager ()

@property (strong, nonatomic) NSManagedObjectContext *context;

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
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
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
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
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

- (NSMutableArray *)getAllUsersFromCoreData {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"UserCoreData" inManagedObjectContext:self.context];
    [request setEntity:entityDescription];
    
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
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    return [results firstObject];
}

- (PostCoreData *)savePostToCoreDataWithPost:(Post * _Nullable)post withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCreatedDate:(NSDate * _Nullable)createdAt withSoldStatus:(BOOL)sold withWatchStatus:(BOOL)watched withWatch:(Watches * _Nullable)watch withWatchCount:(long long)watchCount withAuthor:(UserCoreData * _Nullable)author withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    PostCoreData *postCoreData;
    
    //a new post upload naturally won't immediately have an objectId until it is saved in Parse, so we don't check to see if it already exists bc in this case the user is just creating it
    if (postCoreData) {
        postCoreData = (PostCoreData *)[self getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:context];
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
        postCoreData.watchObjectId = watch.objectId;
        postCoreData.objectId = post.objectId;
        postCoreData.viewed = NO;
        
        //save persistent attributes to core data persisted store
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    return postCoreData;
}

- (UserCoreData *)saveUserToCoreDataWithObjectId:(NSString * _Nullable)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withAddress:(NSString * _Nullable)address withProfilePic:(NSData * _Nullable)imageData withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
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
        
        //save to core data persisted store
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
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
        
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    return conversationCoreData;
}

- (ReviewCoreData *)saveReviewToCoreDataWithObjectId:(NSString *)objectId withSeller:(UserCoreData * _Nullable)seller withRating:(int)rating withReview:(NSString * _Nullable)review withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
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
        
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    return reviewCoreData;
}

@end
