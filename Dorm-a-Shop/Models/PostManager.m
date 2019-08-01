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
@property (strong, nonatomic) NSManagedObjectContext *context;
//@property (strong, nonatomic) NSMutableArray *postsCoreDataArray;

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

- (instancetype) init {
    self = [super init];
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    self.context = self.appDelegate.persistentContainer.viewContext;
    //self.postsCoreDataArray = [[NSMutableArray alloc] init];
    return self;
}

- (void)queryAllPostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    PFUser *currentUser = PFUser.currentUser;
    PFGeoPoint *location = currentUser[@"Location"];
    
    PFQuery *userQuery = [PFUser query];
    [userQuery includeKey:@"Location"];
    [userQuery whereKey:@"Location" nearGeoPoint:location withinKilometers:5.0];
    
    PFQuery *postQuery = [Post query];
    [postQuery orderByDescending:@"createdAt"];
    [postQuery includeKey:@"author"];
    [postQuery whereKey:@"author" matchesQuery:userQuery];
    
    __weak PostManager *weakSelf = self;
    [postQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable posts, NSError * _Nullable error) {
        if (posts) {
            NSMutableArray *allPostsArray = [[NSMutableArray alloc] init];
            
            for (Post *post in posts) {
                PostCoreData *postCoreData = (PostCoreData *)[weakSelf getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:weakSelf.context];
                UserCoreData *userCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:post.author.objectId withContext:weakSelf.context];
                
                if (!userCoreData) {
                    User *user = (User *)post.author;
                    NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                    userCoreData = [weakSelf saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withAddress:user.address withProfilePic:nil withManagedObjectContext:weakSelf.context];
                    
                    [user.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        if (data) {
                            userCoreData.profilePic = data;
                            
                            //save updated attribute to managed object context
                            [weakSelf.context save:nil];
                        } else {
                            NSLog(@"error updating userCoreData image! %@", error.localizedDescription);
                        }
                    }];
                }
                
                if (!postCoreData) {
                    //we don't know if it's watched from this query so we default to NO. this gets handled later. same for watchCount, defaults to 0
                    postCoreData = [weakSelf savePostToCoreDataWithPost:post withImageData:nil withCaption:post.caption withPrice:[post.price doubleValue] withCondition:post.condition withCategory:post.category withTitle:post.title withCreatedDate:post.createdAt withSoldStatus:post.sold withWatchStatus:NO withWatch:nil withWatchCount:0 withAuthor:userCoreData withManagedObjectContext:weakSelf.context];
                    
                    [post.image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        if (data) {
                            postCoreData.image = data;
                            
                            //save updated attribute to managed object context
                            [weakSelf.context save:nil];
                        } else {
                            NSLog(@"error updating postCoreData image! %@", error.localizedDescription);
                        }
                    }];
                    
                    //[self.postsCoreDataArray addObject:post];
                } else {
                    //reset all watch properties to default as they are handled in a different function
                    postCoreData.watched = NO;
                    postCoreData.watchCount = 0;
                    postCoreData.watchObjectId = nil;
                    
                    //update any other properties except for watchStatus and watchCount and watchObjId which are handled in a different function
                    postCoreData.sold = post.sold;
                    
                    //local properties
                    //postCoreData.post = post;
                    //postCoreData.watch = nil;
                    
                    [weakSelf.context save:nil];
                }
                
                [allPostsArray addObject:postCoreData];
            }
            completion(allPostsArray, nil);
        } else {
            NSLog(@"😫😫😫 Error getting posts from database: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
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

- (void)queryWatchedPostsForUser:(PFUser *)user withCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion {
    PFQuery *watchQuery = [Watches query];
    [watchQuery orderByDescending:@"createdAt"];
    [watchQuery includeKey:@"post"];
    [watchQuery includeKey:@"post.author"];
    [watchQuery includeKey:@"post.author.Location"];

    //if user is nil, then we query all watched posts
    if (user) {
        [watchQuery whereKey:@"user" equalTo:user];
    }
    
    __weak PostManager *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable userWatches, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            NSMutableArray *watchedPostsArray = [[NSMutableArray alloc] init];
            
            for (Watches *watch in userWatches) {
                Post *watchedPost = (Post *)watch.post;
                PostCoreData *postCoreData = (PostCoreData *)[weakSelf getCoreDataEntityWithName:@"PostCoreData" withObjectId:watchedPost.objectId withContext:weakSelf.context];
                UserCoreData *userCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:watchedPost.author.objectId withContext:weakSelf.context];
                
                if (!userCoreData) {
                    User *user = (User *)watchedPost.author;
                    NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                    userCoreData = [weakSelf saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withAddress:user.address withProfilePic:nil withManagedObjectContext:weakSelf.context];
                    
                    [user.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        if (data) {
                            userCoreData.profilePic = data;
                            
                            //save updated attribute to managed object context
                            [weakSelf.context save:nil];
                        } else {
                            NSLog(@"error updating userCoreData image! %@", error.localizedDescription);
                        }
                    }];
                }
                if (!postCoreData) {
                    //this really should never get executed if the posts are stored properly upon initialization
                    
                    //handle watch count in a different function that queries watches for post, not watched posts for user
                    postCoreData = [weakSelf savePostToCoreDataWithPost:watchedPost withImageData:nil withCaption:watchedPost.caption withPrice:[watchedPost.price doubleValue] withCondition:watchedPost.condition withCategory:watchedPost.category withTitle:watchedPost.title withCreatedDate:watchedPost.createdAt withSoldStatus:watchedPost.sold withWatchStatus:YES withWatch:watch withWatchCount:0 withAuthor:userCoreData withManagedObjectContext:weakSelf.context];
                    
                    [watchedPost.image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        postCoreData.image = data;
                        [weakSelf.context save:nil];
                    }];
                } else {
                    //postCoreData.watch = watch;
                    postCoreData.watchObjectId = watch.objectId;
                }
                NSLog(@"%lu", postCoreData.watchCount);
                postCoreData.watchCount ++;
                
                if ([PFUser.currentUser.objectId isEqualToString:watch.user.objectId]) {
                    postCoreData.watched = YES;
                }
                
                [weakSelf.context save:nil];
                
                //[self.postsCoreDataArray addObject:watchedPost];
                
                //if the user is not specified (e.g. the query is for all watched posts), THERE WILL PROBABLY BE DUPLICATES IN THIS ARRAY!!!!
                [watchedPostsArray addObject:postCoreData];
            }
            
//            for (PostCoreData *post in watchedPostsArray) {
//                NSLog(@"post: %@, watchCount: %d", post, post.watchCount);
//            }
    
            //don't need to sort by date again as this was already done in the parse query. only sort if this is a direct fetch from core data
            completion(watchedPostsArray, nil);
        }
    }];
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

- (void)queryWatchCountForPost:(Post *)post withCompletion:(void (^)(int, NSError *))completion {
    PFQuery *watchQuery = [Watches query];
    [watchQuery whereKey:@"post" equalTo:post];
    
    PostCoreData *postCoreData = (PostCoreData *)[self getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:self.context];
    
    [watchQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (!error) {
            if (postCoreData) {
                postCoreData.watched = YES;
                postCoreData.watchCount = count;
                [self.context save:nil];
            }
            completion(count, nil);
        } else {
            completion(0, error);
        }
    }];
}

- (void)queryAllUsersWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    PFUser *currentUser = PFUser.currentUser;
    PFGeoPoint *location = currentUser[@"Location"];
    
    PFQuery *userQuery = [PFUser query];
    [userQuery includeKey:@"Location"];
    [userQuery whereKey:@"Location" nearGeoPoint:location withinKilometers:5.0];
    
    __weak PostManager *weakSelf = self;
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable users, NSError * _Nullable error) {
        if (users) {
            NSMutableArray *usersArray = [[NSMutableArray alloc] init];
            
            for (User *user in users) {
                UserCoreData *userCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:user.objectId withContext:weakSelf.context];
                NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                if (!userCoreData) {
                    userCoreData = [weakSelf saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withAddress:user.address withProfilePic:nil withManagedObjectContext:weakSelf.context];
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
                        [weakSelf.context save:nil];
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

- (void)watchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion {
    postCoreData.watchCount ++;
    postCoreData.watched = YES;
    [postCoreData.managedObjectContext save:nil];

    Watches *watch = (Watches *)[Watches new];
    watch.post = (Post *)[PFObject objectWithoutDataWithClassName:@"Post" objectId:postCoreData.objectId];
    NSLog(@"watch.post: %@", watch.post);
    watch.user = (User *)[PFUser currentUser];
    
    [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            completion(error);
        } else {
            //postCoreData.watch = watch;
            postCoreData.watchObjectId = watch.objectId;
            [postCoreData.managedObjectContext save:nil];
            
            completion(nil);
        }
    }];
}

- (void)unwatchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion {
    PFObject *watch = [PFObject objectWithoutDataWithClassName:@"Watches" objectId:postCoreData.watchObjectId];
    
    postCoreData.watchCount --;
    postCoreData.watched = NO;
    postCoreData.watchObjectId = nil;
    [postCoreData.managedObjectContext save:nil];
    
    [watch deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error deleting watch object in server! %@", error.localizedDescription);
            completion(error);
        } else {
            //postCoreData.watch = nil;
            completion(nil);
        }
    }];
}

- (void)setPost:(PostCoreData *)postCoreData sold:(BOOL)sold withCompletion:(void (^)(NSError *))completion {
    postCoreData.sold = sold;
    [postCoreData.managedObjectContext save:nil];
    
    Post *post = (Post *)[PFObject objectWithoutDataWithClassName:@"Post" objectId:postCoreData.objectId];
    post.sold = sold;
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"error updating sold status of post in server! %@", error.localizedDescription);
            completion(error);
        } else {
            completion(nil);
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

- (PostCoreData *)savePostToCoreDataWithPost:(Post * _Nullable)post withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCreatedDate:(NSDate * _Nullable)createdAt withSoldStatus:(BOOL)sold withWatchStatus:(BOOL)watched withWatch:(Watches * _Nullable)watch withWatchCount:(long long)watchCount withAuthor:(UserCoreData * _Nullable)author withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    
    PostCoreData *newPost;
    
    //a new post upload naturally won't immediately have an objectId until it is saved in Parse, so we don't check to see if it already exists bc in this case the user is just creating it
    if (post) {
        newPost = (PostCoreData *)[self getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:context];
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
        newPost.watchCount = watchCount;
        newPost.price = price;
        newPost.createdAt = createdAt;
        newPost.watchObjectId = watch.objectId;
        newPost.objectId = post.objectId;

        //save core data local post and watch properties
//        newPost.post = post;
        //newPost.watch = watch;
        
        //save persistent attributes to core data persisted store
        NSError *error = nil;
        if ([context save:&error] == NO) {
         NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    
    return newPost;
}

- (UserCoreData *)saveUserToCoreDataWithObjectId:(NSString * _Nullable)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withAddress:(NSString * _Nullable)address withProfilePic:(NSData * _Nullable)imageData withManagedObjectContext:(NSManagedObjectContext * _Nullable)context {
    
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
        user.address = address;
        
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
            
            for (PFObject *pfConversation in conversations) {
                Conversation *conversation = (Conversation *) pfConversation;
                ConversationCoreData *conversationCoreData = (ConversationCoreData *)[weakSelf getCoreDataEntityWithName:@"ConversationCoreData" withObjectId:conversation.objectId withContext:weakSelf.context];
                
                if (conversationCoreData) {
                    conversationCoreData.lastText = conversation.lastText;
                    // code that needs to be taken out once bug is fixed
                    conversationCoreData.pfuser = conversation.sender;
                    conversationCoreData.convo = conversation;
                    [weakSelf.context save:nil];
                } else {
                    UserCoreData *senderCoreData;
                    User *otherUser;
                    if(![conversation.sender.objectId isEqualToString:PFUser.currentUser.objectId]) {
                        otherUser = conversation.sender;
                        senderCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:conversation.sender.objectId withContext:weakSelf.context];
                    } else {
                        otherUser = conversation.receiver;
                        senderCoreData = (UserCoreData *)[weakSelf getCoreDataEntityWithName:@"UserCoreData" withObjectId:conversation.receiver.objectId withContext:weakSelf.context];
                    }
                    
                    if (!senderCoreData) {
                        NSString *location = [NSString stringWithFormat:@"(%f, %f)", otherUser.Location.latitude, otherUser.Location.longitude];
                        senderCoreData = [weakSelf saveUserToCoreDataWithObjectId:otherUser.objectId withUsername:otherUser.username withEmail:otherUser.email withLocation:location withAddress:otherUser.address withProfilePic:nil withManagedObjectContext:weakSelf.context];

                        [otherUser.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                            if (data) {
                                senderCoreData.profilePic = data;
                                [weakSelf.context save:nil];
                            } else {
                                NSLog(@"error updating userCoreData image! %@", error.localizedDescription);
                            }
                        }];
                    }
                    
                    conversationCoreData = [weakSelf saveConversationToCoreDataWithObjectId:conversation.objectId withSender:senderCoreData withLastText:conversation.lastText withPfuser:otherUser withPFconvo:conversation withManagedObjectContext:weakSelf.context];
                    conversationCoreData.pfuser = otherUser;
                    conversationCoreData.convo = conversation;
                    [weakSelf.context save:nil];
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
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return mutableResults;
}

//- (PFObject *)getPFObjectWithParseClassName:(NSString *)name objectId:(NSString *)objectId {
//    PFObject *parseObj = [PFObject objectWithoutDataWithClassName:@"Post" objectId:@"ouxUNTAyDv"];
//    ///parseObj.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
//    parseObj[@"title"] = @"TESTING1234567890";
//    [parseObj saveInBackgroundWithBlock:^(BOOL succeededw, NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"Error! %@", error.localizedDescription);
//        } else {
//            NSLog(@"Success!");
//        }
//    }];
//
//    //    PFQuery *myQuery = [PFQuery queryWithClassName:@"Watches"];
//    //    [myQuery whereKey:@"post" equalTo:[PFObject objectWithoutDataWithClassName:@"Post" objectId:@"Gg0gBwfF3M"]];
//    //
//    //    [myQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
//    //        if (error) {
//    //            NSLog(@"Error! %@", error.localizedDescription);
//    //        } else {
//    //            NSLog(@"Result: %@", objects);
//    //        }
//    //    }];
//}

@end
