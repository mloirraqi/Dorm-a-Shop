//
//  ParseManager.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/1/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "ParseManager.h"
#import "Post.h"
#import "Watches.h"
#import "User.h"
#import "Conversation.h"
#import "Review.h"
#import "PostCoreData+CoreDataClass.h"
#import "UserCoreData+CoreDataClass.h"
#import "ConversationCoreData+CoreDataClass.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "LocationManager.h"
#import "CoreDataManager.h"
@import Parse;

@interface ParseManager ()

@property (strong, nonatomic) NSManagedObjectContext *context;

@end

@implementation ParseManager

#pragma mark Singleton Methods

+ (instancetype)shared {
    static ParseManager *sharedParseManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedParseManager = [[self alloc] init];
    });
    return sharedParseManager;
}

- (instancetype) init {
    self = [super init];
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    return self;
}

- (void)queryAllPostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    PFUser *currentUser = PFUser.currentUser;
    PFGeoPoint *location = currentUser[@"Location"];
    
    PFQuery *userQuery = [PFUser query];
    [userQuery includeKey:@"Location"];
    [userQuery whereKey:@"Location" nearGeoPoint:location withinKilometers:kilometers];
    
    PFQuery *postQuery = [Post query];
    [postQuery orderByDescending:@"createdAt"];
    [postQuery includeKey:@"author"];
    [postQuery whereKey:@"author" matchesQuery:userQuery];
    
    __weak ParseManager *weakSelf = self;
    [postQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable posts, NSError * _Nullable error) {
        if (posts) {
            NSMutableArray *allPostsArray = [[NSMutableArray alloc] init];
            
            for (Post *post in posts) {
                PostCoreData *postCoreData = (PostCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:weakSelf.context];
                UserCoreData *userCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:post.author.objectId withContext:weakSelf.context];
                
                if (!userCoreData) {
                    User *user = (User *)post.author;
                    NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                    userCoreData = [[CoreDataManager shared] saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withAddress:user.address withProfilePic:nil inRadius:YES withManagedObjectContext:weakSelf.context];
                    
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
                    postCoreData = [[CoreDataManager shared] savePostToCoreDataWithPost:post withImageData:nil withCaption:post.caption withPrice:[post.price doubleValue] withCondition:post.condition withCategory:post.category withTitle:post.title withCreatedDate:post.createdAt withSoldStatus:post.sold withWatchStatus:NO withWatch:nil withWatchCount:0 withAuthor:userCoreData withManagedObjectContext:weakSelf.context];
                    
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
                } else {
                    //reset all watch properties to default as they are handled in a different function
                    postCoreData.watched = NO;
                    postCoreData.watchCount = 0;
                    postCoreData.watchObjectId = nil;
                    
                    //update any other properties except for watchStatus and watchCount and watchObjId which are handled in a different function
                    postCoreData.sold = post.sold;
                    
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
    
    __weak ParseManager *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable userWatches, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            NSMutableArray *watchedPostsArray = [[NSMutableArray alloc] init];
            
            for (Watches *watch in userWatches) {
                Post *watchedPost = (Post *)watch.post;
                PostCoreData *postCoreData = (PostCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"PostCoreData" withObjectId:watchedPost.objectId withContext:weakSelf.context];
                UserCoreData *userCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:watchedPost.author.objectId withContext:weakSelf.context];
                
                if (!userCoreData && postCoreData) {
                    //this really shouldn't ever execute if posts/users were previoiusly saved to core data properly, it's just a failsafe
                    User *user = (User *)watchedPost.author;
                    NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                    userCoreData = [[CoreDataManager shared] saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withAddress:user.address withProfilePic:nil inRadius:YES withManagedObjectContext:weakSelf.context];

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
                
                //posts should already be populated in core data with - (void)queryAllPostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion before calling this function
                if (postCoreData) {
                    postCoreData.watchObjectId = watch.objectId;
                    postCoreData.watchCount ++;
                    
                    if ([PFUser.currentUser.objectId isEqualToString:watch.user.objectId]) {
                        postCoreData.watched = YES;
                    }
                    
                    [weakSelf.context save:nil];
                    
                    //if the user is not specified (e.g. the query is for all watched posts), THERE WILL PROBABLY BE DUPLICATES IN THIS ARRAY!!!!
                    [watchedPostsArray addObject:postCoreData];
                }
            }
            
            //don't need to sort by date again as this was already done in the parse query. only sort if this is a direct fetch from core data
            completion(watchedPostsArray, nil);
        }
    }];
}

- (void)queryWatchCountForPost:(Post *)post withCompletion:(void (^)(int, NSError *))completion {
    PFQuery *watchQuery = [Watches query];
    [watchQuery whereKey:@"post" equalTo:post];
    
    PostCoreData *postCoreData = (PostCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:self.context];
    
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
    
    __weak ParseManager *weakSelf = self;
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable users, NSError * _Nullable error) {
        if (users) {
            NSMutableArray *usersArray = [[NSMutableArray alloc] init];
            
            for (User *user in users) {
                UserCoreData *userCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:user.objectId withContext:weakSelf.context];
                NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
                if (!userCoreData) {
                    userCoreData = [[CoreDataManager shared] saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withAddress:user.address withProfilePic:nil inRadius:YES withManagedObjectContext:weakSelf.context];
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
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
            [usersArray sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            completion(usersArray, nil);
        } else {
            NSLog(@"😫😫😫 Error getting posts from database: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
}

- (void)queryConversationsFromParseWithCompletion:(void (^)(NSMutableArray<ConversationCoreData *> *, NSError *))completion {
    NSMutableArray *conversationsCoreDataArray = [[NSMutableArray alloc] init];
    PFQuery *sentQuery = [PFQuery queryWithClassName:@"Convos"];
    [sentQuery whereKey:@"sender" equalTo:[PFUser currentUser]];
    
    PFQuery *recQuery = [PFQuery queryWithClassName:@"Convos"];
    [recQuery whereKey:@"receiver" equalTo:[PFUser currentUser]];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[sentQuery, recQuery]];
    [query orderByDescending:@"updatedAt"];
    [query includeKey:@"sender"];
    [query includeKey:@"receiver"];
    
    __weak ParseManager *weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable conversations, NSError * _Nullable error) {
        if (conversations) {
            for (PFObject *pfConversation in conversations) {
                Conversation *conversation = (Conversation *) pfConversation;
                ConversationCoreData *conversationCoreData = (ConversationCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"ConversationCoreData" withObjectId:conversation.objectId withContext:weakSelf.context];
                
                UserCoreData *senderCoreData;
                User *otherUser;
                if(![conversation.sender.objectId isEqualToString:PFUser.currentUser.objectId]) {
                    otherUser = conversation.sender;
                    senderCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:conversation.sender.objectId withContext:weakSelf.context];
                } else {
                    otherUser = conversation.receiver;
                    senderCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:conversation.receiver.objectId withContext:weakSelf.context];
                }
                
                if (!senderCoreData) {
                    NSString *location = [NSString stringWithFormat:@"(%f, %f)", otherUser.Location.latitude, otherUser.Location.longitude];
                    senderCoreData = [[CoreDataManager shared] saveUserToCoreDataWithObjectId:otherUser.objectId withUsername:otherUser.username withEmail:otherUser.email withLocation:location withAddress:otherUser.address withProfilePic:nil inRadius:NO withManagedObjectContext:weakSelf.context];
                    
                    [otherUser.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        if (data) {
                            senderCoreData.profilePic = data;
                            [weakSelf.context save:nil];
                        } else {
                            NSLog(@"error updating userCoreData image! %@", error.localizedDescription);
                        }
                    }];
                }
                
                if (conversationCoreData) {
                    conversationCoreData.lastText = conversation.lastText;
                    conversationCoreData.updatedAt = conversation.updatedAt;
                    conversationCoreData.sender = senderCoreData;
                    [weakSelf.context save:nil];
                } else {
                    conversationCoreData = [[CoreDataManager shared] saveConversationToCoreDataWithObjectId:conversation.objectId withDate:conversation.updatedAt withSender:senderCoreData withLastText:conversation.lastText withManagedObjectContext:weakSelf.context];
                    [weakSelf.context save:nil];
                }
                [conversationsCoreDataArray addObject:conversationCoreData];
            }
            
            NSMutableArray *mutableResults = [NSMutableArray arrayWithArray:conversationsCoreDataArray];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updatedAt" ascending:NO];
            [mutableResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            completion(mutableResults, nil);
        } else {
            NSLog(@"😫😫😫 Error getting inbox: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
}

- (void)queryReviewsForSeller:(User *)seller withCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    
}

- (void)watchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion {
    postCoreData.watchCount ++;
    postCoreData.watched = YES;
    [postCoreData.managedObjectContext save:nil];
    
    Watches *watch = (Watches *)[Watches new];
    watch.post = (Post *)[PFObject objectWithoutDataWithClassName:@"Post" objectId:postCoreData.objectId];
    watch.user = (User *)[PFUser currentUser];
    
    [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            completion(error);
        } else {
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
    
    newPost.image = [self getPFFileFromImage:image];
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

- (PFFileObject *)getPFFileFromImage:(UIImage * _Nullable)image {
    if (!image) {
        return nil;
    }
    NSData *imageData = UIImagePNGRepresentation(image);
    if (!imageData) {
        return nil;
    }
    return [PFFileObject fileObjectWithName:@"image.png" data:imageData];
}

- (void)viewPost:(PostCoreData *)postCoreData{
    if(!postCoreData.viewed) {
        postCoreData.viewed = YES;
        [postCoreData.managedObjectContext save:nil];
        
        PFObject *view = [PFObject objectWithClassName:@"Views"];
        view[@"post"] = (Post *)[PFObject objectWithoutDataWithClassName:@"Post" objectId:postCoreData.objectId];
        view[@"user"] = (User *)[PFUser currentUser];
        
        [view saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (error) {
                NSLog(@"😫😫😫 Error getting inbox: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)queryViewedPostswithCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion {
    PFQuery *viewQuery = [PFQuery queryWithClassName:@"Views"];
    [viewQuery orderByDescending:@"createdAt"];
    [viewQuery includeKey:@"post"];
    [viewQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    
    __weak ParseManager *weakSelf = self;
    [viewQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable views, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        } else {
            NSMutableArray *watchedPostsArray = [[NSMutableArray alloc] init];
            
            for (PFObject *view in views) {
                Post *viewedPost = (Post *)view[@"post"];
                PostCoreData *postCoreData = (PostCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"PostCoreData" withObjectId:viewedPost.objectId withContext:weakSelf.context];
                postCoreData.viewed = YES;
                [weakSelf.context save:nil];
                [watchedPostsArray addObject:postCoreData];
            }
            completion(watchedPostsArray, nil);
        }
    }];
}
            
- (void)postReviewToParseWithSeller:(User *)seller withRating:(NSNumber * _Nullable)rating withReview:(NSString * _Nullable)review withCompletion:(void (^)(Review * _Nullable, NSError * _Nullable))completion {
    Review *newReview = [Review new];
    
    newReview.reviewer = (User *)PFUser.currentUser;
    newReview.seller = seller;
    newReview.rating = rating;
    newReview.review = review;
    
    NSLog(@"seller: %@, newReview.seller: %@", seller, newReview.seller);
    [newReview saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            completion(nil, error);
        } else {
            completion(newReview, nil);
        }
    }];
}

@end
