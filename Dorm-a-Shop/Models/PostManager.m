//
//  PostManager.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "PostManager.h"
#import "Post.h"
#import "Watches.h"
#import "User.h"
#import "Conversation.h"
#import "PostCoreData+CoreDataClass.h"
#import "UserCoreData+CoreDataClass.h"
#import "ConversationCoreData+CoreDataClass.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "LocationManager.h"
@import Parse;

@interface PostManager ()

@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation PostManager

#pragma mark Singleton Methods

+ (instancetype)shared {
    static PostManager *sharedPostManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPostManager = [[self alloc] init];
    });
    return sharedPostManager;
}

- (void)queryAllPostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    PFUser *currentUser = PFUser.currentUser;
    PFGeoPoint *location = currentUser[@"Location"];
    
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"Location" nearGeoPoint:location withinKilometers:5.0];
    
    PFQuery *postQuery = [Post query];
    [postQuery orderByDescending:@"createdAt"];
    [postQuery includeKey:@"author"];
    [postQuery whereKey:@"author" matchesQuery:userQuery];
    
    __weak PostManager *weakSelf = self;
    [postQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable posts, NSError * _Nullable error) {
        if (posts) {
            NSMutableArray *activePostsArray = [[NSMutableArray alloc] init];
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
            
            for (Post *post in posts) {
                PostCoreData *postCoreData = (PostCoreData *)[weakSelf getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:context];
                UserCoreData *userCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:post.author.objectId withContext:context];
                
                if (!userCoreData) {
                    User *user = (User *)post.author;
                    NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                    userCoreData = [weakSelf saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withProfilePic:nil withManagedObjectContext:context];
                    
                    [user.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        if (data) {
                            userCoreData.profilePic = data;
                            
                            //save updated attribute to managed object context
                            [context save:nil];
                        } else {
                            NSLog(@"error updating userCoreData image! %@", error.localizedDescription);
                        }
                    }];
                }
                
                if (!postCoreData) {
                    //we don't know if it's watched from this query so we default to NO. this gets handled later. same for watchCount, defaults to 0
                    postCoreData = [weakSelf savePostToCoreDataWithObjectId:post.objectId withImageData:[[NSData alloc] init] withCaption:post.caption withPrice:[post.price doubleValue] withCondition:post.condition withCategory:post.category withTitle:post.title withCreatedDate:post.createdAt withSoldStatus:post.sold withWatchStatus:NO withWatchObjectId:nil withWatchCount:0 withAuthor:userCoreData withManagedObjectContext:context];
                    
                    [post.image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        if (data) {
                            postCoreData.image = data;
                            
                            //save updated attribute to managed object context
                            [context save:nil];
                        } else {
                            NSLog(@"error updating postCoreData image! %@", error.localizedDescription);
                        }
                    }];
                } else {
                    //reset all watch properties to default as they are handled in a different function
                    postCoreData.watchObjectId = nil;
                    postCoreData.watched = NO;
                    postCoreData.watchCount = 0;
                    
                    //update any other properties except for watch and watchCount and watchObjId which are handled in a different function
                    postCoreData.sold = post.sold;
                    [context save:nil];
                }
                [activePostsArray addObject:postCoreData];
            }
            
            completion(activePostsArray, nil);
        } else {
            NSLog(@"😫😫😫 Error getting posts from database: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
}

- (NSMutableArray *)getActivePostsFromCoreData {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"sold == %@", [NSNumber numberWithBool:NO]]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults; //firstObject is nil if results has length 0
}

- (void)queryWatchedPostsForUser:(PFUser *)user withCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion {
    PFQuery *watchQuery = [Watches query];
    [watchQuery orderByDescending:@"createdAt"];
    [watchQuery includeKey:@"post"];

    //if user is nil, then we query all watched posts
    if (user) {
        [watchQuery whereKey:@"user" equalTo:user];
    }
    
    __weak PostManager *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable userWatches, NSError * _Nullable error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
            completion(nil, error);
        } else {
            NSMutableArray *watchedPostsArray = [[NSMutableArray alloc] init];
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
            
            for (Watches *watch in userWatches) {
                Post *watchedPost = (Post *)watch.post;
                PostCoreData *postCoreData = (PostCoreData *)[weakSelf getCoreDataEntityWithName:@"PostCoreData" withObjectId:watchedPost.objectId withContext:context];
                UserCoreData *userCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:watchedPost.author.objectId withContext:context];
                
                if (!userCoreData) {
                    User *user = (User *)watchedPost.author;
                    NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                    userCoreData = [weakSelf saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withProfilePic:nil withManagedObjectContext:context];
                    
                    [user.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        if (data) {
                            userCoreData.profilePic = data;
                            
                            //save updated attribute to managed object context
                            [context save:nil];
                        } else {
                            NSLog(@"error updating userCoreData image! %@", error.localizedDescription);
                        }
                    }];
                }
                if (!postCoreData) {
                    //this really should never get executed if the posts are stored properly upon initialization
                    
                    //handle watch count in a different function that queries watches for post, not watched posts for user
                    //init watch count to 1 since this is a watched post by the first user paired with it in the watch list
                    postCoreData = [weakSelf savePostToCoreDataWithObjectId:watchedPost.objectId withImageData:nil withCaption:watchedPost.caption withPrice:[watchedPost.price doubleValue] withCondition:watchedPost.condition withCategory:watchedPost.category withTitle:watchedPost.title withCreatedDate:watchedPost.createdAt withSoldStatus:watchedPost.sold withWatchStatus:YES withWatchObjectId:watchedPost.objectId withWatchCount:1 withAuthor:userCoreData withManagedObjectContext:context];
                    
                    [watchedPost.image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        postCoreData.image = data;
                        [context save:nil];
                        
                    }];
                }
                postCoreData.watchObjectId = watch.objectId;
                postCoreData.watchCount ++;
                
                if ([PFUser.currentUser.objectId isEqualToString:postCoreData.author.objectId]) {
                    postCoreData.watched = YES;
                }
                
                [context save:nil];
                
                [watchedPostsArray addObject:postCoreData];
            }
    
            //don't need to sort by date again as this was already done in the parse query. only sort if this is a direct fetch from core data
            completion(watchedPostsArray, nil);
        }
    }];
}

- (NSMutableArray *)getActiveWatchedPostsForCurrentUserFromCoreData {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"(watched == %@) AND (sold == %@)", [NSNumber numberWithBool:YES], [NSNumber numberWithBool:NO]]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

- (void)queryWatchCountForPost:(Post *)post withCompletion:(void (^)(int, NSError *))completion {
    PFQuery *watchQuery = [Watches query];
    [watchQuery orderByDescending:@"createdAt"];
    [watchQuery whereKey:@"post" equalTo:post];
    
    __weak PostManager *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable userWatches, NSError * _Nullable error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
            completion(0, error);
        } else {
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
            
            int watchCount = 0;
            for (PFObject *watch in userWatches) {
                Post *watchedPost = watch[@"post"];
                PostCoreData *postCoreData = (PostCoreData *)[weakSelf getCoreDataEntityWithName:@"PostCoreData" withObjectId:watchedPost.objectId withContext:context];
                if (postCoreData) {
                    postCoreData.watched = YES;
                    postCoreData.watchCount ++;
                }
                watchCount ++;
            }
            [context save:nil];
            completion(watchCount, nil);
        }
    }];
}

- (void)queryAllUsersWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    PFUser *currentUser = PFUser.currentUser;
    PFGeoPoint *location = currentUser[@"Location"];
    
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"Location" nearGeoPoint:location withinKilometers:5.0];
    
    __weak PostManager *weakSelf = self;
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable users, NSError * _Nullable error) {
        if (users) {
            NSMutableArray *usersArray = [[NSMutableArray alloc] init];
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
            
            for (User *user in users) {
                UserCoreData *userCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:user.objectId withContext:context];
                NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                if (!userCoreData) {
                    userCoreData = [weakSelf saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withProfilePic:nil withManagedObjectContext:context];
                } else {
                    //update any properties a user could have changed, except image, which is handled below
                    userCoreData.location = location;
                    userCoreData.username = user.username;
                    userCoreData.email = userCoreData.email;
                }
                //in either case, either create the profile image or make sure it's up to date
                [user.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                    //set image later
                    if (data) {
                        userCoreData.profilePic = data;
                        
                        //save updated attribute to managed object context
                        [context save:nil];
                    } else {
                        NSLog(@"error updating userCoreData image! %@", error.localizedDescription);
                    }
                }];
                [usersArray addObject:userCoreData];
            }
            NSMutableArray *usersResult = [NSMutableArray arrayWithArray:usersArray];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
            [usersResult sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            completion(usersResult, nil);
        } else {
            NSLog(@"😫😫😫 Error getting posts from database: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
}

- (NSMutableArray *)getProfilePostsFromCoreDataForUser:(UserCoreData *)user {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"author.objectId == %@", user.objectId]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
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
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"UserCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

- (void)watchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion {
    postCoreData.watchCount ++;
    postCoreData.watched = YES;
    [postCoreData.managedObjectContext save:nil];
    
    PFQuery *postQuery = [Post query];
    [postQuery getObjectInBackgroundWithId:postCoreData.objectId block:^(PFObject * _Nullable post, NSError * _Nullable error) {
        if (post) {
            Watches *watch = (Watches *)[Watches new];
            watch.post = post;
            watch.user = [PFUser currentUser];
            
            [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error saving new object in server! %@", error.localizedDescription);
                    completion(error);
                } else {
                    postCoreData.watchObjectId = watch.objectId;
                    [postCoreData.managedObjectContext save:nil];
                    NSLog(@"watched objected id %@", postCoreData.watchObjectId);
                    
                    completion(nil);
                }
            }];
        } else {
            NSLog(@"error querying post object by objectId! %@", error.localizedDescription);
            completion(error);
        }
    }];
}

- (void)unwatchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion {
    postCoreData.watchCount --;
    postCoreData.watched = NO;
    [postCoreData.managedObjectContext save:nil];

    PFQuery *watchQuery = [Watches query];
    [watchQuery getObjectInBackgroundWithId:postCoreData.watchObjectId block:^(PFObject * _Nullable watch, NSError * _Nullable error) {
        if (watch) {
            [watch deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error deleting watch object in server! %@", error.localizedDescription);
                    completion(error);
                } else {
                    postCoreData.watchObjectId = nil;
                    [postCoreData.managedObjectContext save:nil];
                    completion(nil);
                }
            }];
        } else {
            NSLog(@"error querying watch object by objectId! %@", error.localizedDescription);
            completion(error);
        }
    }];
}

- (void)setPost:(PostCoreData *)postCoreData sold:(BOOL)sold withCompletion:(void (^)(NSError *))completion {
    postCoreData.sold = sold;
    [postCoreData.managedObjectContext save:nil];
    NSLog(@"post.sold: %d", postCoreData.sold);
    
    PFQuery *postQuery = [Post query];
    [postQuery getObjectInBackgroundWithId:postCoreData.objectId block:^(PFObject * _Nullable post, NSError * _Nullable error) {
        if (post) {
            ((Post *)post).sold = sold;
            [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error updating sold status of post in server! %@", error.localizedDescription);
                    completion(error);
                } else {
                    completion(nil);
                }
            }];
        } else {
            NSLog(@"error querying post by objectId in server! %@", error.localizedDescription);
            completion(error);
        }
    }];
}

- (void)postListingToParseWithImage:(UIImage * _Nullable)image withCaption:(NSString * _Nullable)caption withPrice:(NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post *, NSError *))completion {
    Post *newPost = [Post new];
    
    newPost.image = [PostManager getPFFileFromImage:image];
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
    
    [newPost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            completion(nil, error);
        } else {
            completion(newPost, nil);
        }
    }];
}

+ (PFFileObject *)getPFFileFromImage:(UIImage * _Nullable)image {
    if (!image) {
        return nil;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    if (!imageData) {
        return nil;
    }
    return [PFFileObject fileObjectWithName:@"image.png" data:imageData];
}

- (PostCoreData *)savePostToCoreDataWithObjectId:(NSString * _Nullable)postObjectId withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCreatedDate:(NSDate * _Nullable)createdAt withSoldStatus:(BOOL)sold withWatchStatus:(BOOL)watched withWatchObjectId:(NSString * _Nullable)watchObjectId withWatchCount:(long long)watchCount withAuthor:(UserCoreData * _Nullable)author withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    
    PostCoreData *newPost;
    
    //a new post upload naturally won't immediately have an objectId until it is saved in Parse, so we don't check to see if it already exists bc in this case the user is just creating it
    if (postObjectId) {
        newPost = (PostCoreData *)[self getCoreDataEntityWithName:@"PostCoreData" withObjectId:postObjectId withContext:context];
    }
    
    //if post doesn't already exist in core data, then create it
    if (!newPost) {
        newPost = (PostCoreData *)[NSEntityDescription insertNewObjectForEntityForName:@"PostCoreData" inManagedObjectContext:context];
        newPost.author = author;
        
        //the author has to exist to set its associated post. author should exist, it should have been set during signup. this is just to ensure it exists
        if (author && !author.post) {
            author.post = [[NSSet alloc] initWithObjects:newPost, nil];
        } else if (author) {
            author.post = [author.post setByAddingObject:newPost];
        }
        
        newPost.image = imageData;
        newPost.caption = caption;
        newPost.condition = condition;
        newPost.category = category;
        newPost.title = title;
        newPost.sold = sold;
        newPost.watched = watched;
        newPost.watchObjectId = watchObjectId;
        newPost.watchCount = watchCount;
        newPost.price = price;
        newPost.objectId = postObjectId;
        newPost.createdAt = createdAt;

        //save to core data persisted store
        NSError *error = nil;
        if ([context save:&error] == NO) {
         NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    return newPost;
}

- (UserCoreData *)saveUserToCoreDataWithObjectId:(NSString * _Nullable)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withProfilePic:(NSData * _Nullable)imageData withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    
    UserCoreData *user;
    if (userObjectId) {
        user = (UserCoreData *)[self getCoreDataEntityWithName:@"UserCoreData" withObjectId:userObjectId withContext:context];
    }
    
    //if post doesn't already exist in core data, then create it
    if (!user) {
        user = (UserCoreData *)[NSEntityDescription insertNewObjectForEntityForName:@"UserCoreData" inManagedObjectContext:context];
        
        user.objectId = userObjectId;
        user.profilePic = imageData;
        user.email = email;
        user.location = location;
        user.username = username;
        
        //save to core data persisted store
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    return user;
}

- (ConversationCoreData *)saveConversationToCoreDataWithObjectId:(NSString * _Nullable)conversationObjectId withSender:(UserCoreData * _Nullable)sender withLastText:(NSString * _Nullable)lastText withPfuser:(PFUser *)pfuser withPFconvo:(PFObject *)convo withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    
    ConversationCoreData *conversation;
    if (conversationObjectId) {
        conversation = (ConversationCoreData *)[self getCoreDataEntityWithName:@"ConversationCoreData" withObjectId:conversationObjectId withContext:context];
    }
    
    if (!conversation) {
        conversation = (ConversationCoreData *)[NSEntityDescription insertNewObjectForEntityForName:@"ConversationCoreData" inManagedObjectContext:context];
        conversation.objectId = conversationObjectId;
        conversation.sender = sender;
        conversation.lastText = lastText;
        conversation.pfuser = (User *) pfuser;
        conversation.convo = (Conversation *) convo;
        
        NSError *error = nil;
        if ([context save:&error] == NO) {
            NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    return conversation;
}

- (void)queryConversationsFromParseWithCompletion:(void (^)(NSMutableArray<ConversationCoreData *> *, NSError *))completion {
    PFQuery *sentQuery = [PFQuery queryWithClassName:@"Convos"];
    [sentQuery whereKey:@"sender" equalTo:[PFUser currentUser]];
    
    PFQuery *recQuery = [PFQuery queryWithClassName:@"Convos"];
    [recQuery whereKey:@"receiver" equalTo:[PFUser currentUser]];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[sentQuery, recQuery]];
    [query orderByDescending:@"updatedAt"];
    [query includeKey:@"sender"];
    [query includeKey:@"receiver"];
    
    __weak PostManager *weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable conversations, NSError * _Nullable error) {
        if (conversations) {
            NSMutableArray *conversationsCoreDataArray = [[NSMutableArray alloc] init];
            
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
            
            for (PFObject *pfConversation in conversations) {
                Conversation *conversation = (Conversation *) pfConversation;
                ConversationCoreData *conversationCoreData = (ConversationCoreData *)[weakSelf getCoreDataEntityWithName:@"ConversationCoreData" withObjectId:conversation.objectId withContext:context];
                
                if (conversationCoreData) {
                    conversationCoreData.lastText = conversation.lastText;
                    [context save:nil];
                } else {
                    UserCoreData *senderCoreData;
                    User *otherUser;
                    if(![conversation.sender.objectId isEqualToString:PFUser.currentUser.objectId])
                    {
                        otherUser = conversation.sender;
                        senderCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:conversation.sender.objectId withContext:context];
                    } else {
                        otherUser = conversation.receiver;
                        senderCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:conversation.receiver.objectId withContext:context];
                    }
                    
                    if (!senderCoreData) {
                        NSString *location = [NSString stringWithFormat:@"(%f, %f)", otherUser.Location.latitude, otherUser.Location.longitude];
                        senderCoreData = [weakSelf saveUserToCoreDataWithObjectId:otherUser.objectId withUsername:otherUser.username withEmail:otherUser.email withLocation:location withProfilePic:nil withManagedObjectContext:context];

                        [otherUser.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                            if (data) {
                                senderCoreData.profilePic = data;
                                [context save:nil];
                            } else {
                                NSLog(@"error updating userCoreData image! %@", error.localizedDescription);
                            }
                        }];
                    }
                    
                    conversationCoreData = [weakSelf saveConversationToCoreDataWithObjectId:conversation.objectId withSender:senderCoreData withLastText:conversation.lastText withPfuser:otherUser withPFconvo:conversation withManagedObjectContext:context];
                    conversationCoreData.pfuser = otherUser;
                    conversationCoreData.convo = conversation;
                    [context save:nil];
                }
                [conversationsCoreDataArray addObject:conversationCoreData];
            }
            completion(conversationsCoreDataArray, nil);
        } else {
            NSLog(@"😫😫😫 Error getting inbox: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
}

- (NSMutableArray *)getAllConvosFromCoreData {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"ConversationCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    [request setReturnsObjectsAsFaults:NO];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:results];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

@end
