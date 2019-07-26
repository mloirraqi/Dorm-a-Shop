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
#import "PostCoreData+CoreDataClass.h"
#import "UserCoreData+CoreDataClass.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "LocationManager.h"
@import Parse;

@interface PostManager ()

@property (strong, nonatomic) AppDelegate *appDelegate;

@end

//PLEASE NOTE THERE IS SIGNIFICANT COMMENTED OUT CODE IN THIS FILE THAT WE STILL NEED TO REFERENCE GOING FORWARD, WILL DELETE AS SOON AS WE NO LONGER NEED IT

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

- (void)queryActivePostsWithinKilometers:(int)kilometers withCompletion:(void (^)(NSMutableArray *, NSError *))completion {
    //    if (self.allPostsArray != nil) {
    //        completion(self.allPostsArray, nil);
    //    } else {
    PFQuery *postQuery = [Post query];
    [postQuery orderByDescending:@"createdAt"];
    [postQuery includeKey:@"author"];
    [postQuery whereKey:@"sold" equalTo:@NO];
    
    CLLocation *currentLocation = [[LocationManager sharedInstance] currentLocation];
    PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
    //[postQuery whereKey:@"location" nearGeoPoint:location withinKilometers:kilometers];
    
    [postQuery includeKey:@"image"];
    
    __weak PostManager *weakSelf = self;
    [postQuery findObjectsInBackgroundWithBlock:^(NSArray<PostCoreData *> * _Nullable posts, NSError * _Nullable error) {
        NSLog(@"%d", posts == nil);
        if (posts) {
            //weakSelf.allPostsArray = [NSMutableArray arrayWithArray:posts];
            NSMutableArray *allPostsArray = [[NSMutableArray alloc] init];
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
            
            for (Post *post in posts) {
                PostCoreData *postCoreData = (PostCoreData *)[weakSelf getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:context];
                if (postCoreData) {
                    postCoreData.sold = post.sold;
                    //update any other properties except for watch and watchCount which are handled in a different function
                } else {
                    //nested query???????????????????????????
                    postCoreData = [weakSelf savePostWithObjectId:post.objectId withImageData:nil withCaption:post.caption withPrice:[post.price doubleValue] withCondition:post.condition withCategory:post.category withTitle:post.title toCoreDataWithManagedObjectContext:context];
                    NSLog(@"post core data: %@", postCoreData);
                    [post.image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                        //set image later
                        postCoreData.image = data;
                    }];
                }
                NSLog(@"post core data: %@", postCoreData);
                [allPostsArray addObject:postCoreData];
            }
            
            completion(allPostsArray, nil);
        } else {
            NSLog(@"😫😫😫 Error getting posts from database: %@", error.localizedDescription);
            completion(nil, error);
        }
    }];
    //    }
}

//get from core data
- (NSMutableArray *)getActivePostsFromCoreData {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    //[request setPredicate:[NSPredicate predicateWithFormat:@"sold = %@", NO]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    NSLog(@"posts from core data: %@", results);
    NSMutableArray *temp = [NSMutableArray arrayWithArray:results]; //firstObject is nil if results has length 0
    NSLog(@"temp %@", temp);
    return temp;
}

- (void)queryWatchedPostsForCurrentUserWithCompletion:(void (^)(NSMutableArray<PostCoreData *> * _Nullable, NSError * _Nullable))completion {
//    if (self.watchedPostsArray != nil) {
//        completion(self.watchedPostsArray, nil);
//    } else {
        PFQuery *watchQuery = [Watches query];
        [watchQuery orderByDescending:@"createdAt"];
        [watchQuery whereKey:@"user" equalTo:[PFUser currentUser]];
        [watchQuery includeKey:@"post"];
        
        __weak PostManager *weakSelf = self;
        [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable userWatches, NSError * _Nullable error) {
            if (error) {
                NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
                completion(nil, error);
            } else {
                NSMutableArray *watchedPostsArray = [[NSMutableArray alloc] init];
                AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
                
                for (PFObject *watch in userWatches) {
                    Post *watchedPost = watch[@"post"];
                    PostCoreData *postCoreData = (PostCoreData *)[weakSelf getCoreDataEntityWithName:@"PostCoreData" withObjectId:watchedPost.objectId withContext:context];
                    if (!postCoreData) {
                        //this really should never get executed if the posts are stored properly upon initialization
                        //also nested query???????????????????????????
                        postCoreData = [weakSelf savePostWithObjectId:watchedPost.objectId withImageData:nil withCaption:watchedPost.caption withPrice:[watchedPost.price doubleValue] withCondition:watchedPost.condition withCategory:watchedPost.category withTitle:watchedPost.title toCoreDataWithManagedObjectContext:context];
                        [watchedPost.image getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                            //set image later
                            postCoreData.image = data;
                        }];
                    }
                    postCoreData.watched = YES;
                    postCoreData.watchObjectId = watch.objectId;
                    [watchedPostsArray addObject:postCoreData];
                }
                completion(watchedPostsArray, nil);
            }
        }];
//    }
}

//get from core data, not server
- (NSMutableArray *)getActiveWatchedPostsForCurrentUserFromCoreData {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"watched = %@, sold = %@", YES, NO]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    return [NSMutableArray arrayWithArray:results];
}

/*- (BOOL)getCurrentUserWatchStatusFromCoreDataForPost:(PostCoreData *)post {
    //we shouldn't need to query to determine whether the current user has watched something now that we have core data
/*    // WE STILL NEED THIS COMMENTED OUT CODE FOR NOW, WILL REMOVE LATER
//    if (post.watchCount != nil) {
//        NSLog(@"watch count is: %@", post.watchCount);
//        completion(post, nil);
//    } else {
        PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
        [watchQuery orderByDescending:@"createdAt"];
        [watchQuery whereKey:@"post" equalTo:post];

        [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable postWatches, NSError * _Nullable error) {
            if (error) {
                completion(nil, error);
            } else {
                post.watchCount = [NSNumber numberWithUnsignedInteger:postWatches.count];
                if (postWatches.count > 0) {
                    bool watched = NO;
                    for (PFObject *watch in postWatches) {
                        if ([((PFObject *)watch[@"user"]).objectId isEqualToString:[PFUser currentUser].objectId]) {
                            post.watch = watch;
                            watched = YES;
                            break;
                        }
                    }
                    if (!watched) {
                        post.watch = nil;
                    }
                } else {
                    post.watch = nil;
                }
                completion(post, nil);
            }
        }];
    //}
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *context = [post managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"objectId = %@", post.objectId]];
    [request setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    if (![results firstObject]) {
        return NO;  //firstObject is nil if results has length 0
    }
    
    return ((PostCoreData *)[results firstObject]).watched;
}*/

- (void)queryWatchCountForPost:(Post *)post withCompletion:(void (^)(int, NSError *))completion {
    PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
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
            completion(watchCount, nil);
        }
    }];
}

- (NSMutableArray *)getProfilePostsFromCoreDataForUser:(UserCoreData *)user {
    /*NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PostCoreData *post, NSDictionary *bindings) {
     return [post.author.objectId isEqualToString:user.objectId];
     }];
     NSArray *allPostsArray = [self getAllPostsFromCoreData];
     return [NSMutableArray arrayWithArray:[allPostsArray filteredArrayUsingPredicate:predicate]];*/
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"author = %@", user]];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects for current user: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    return [NSMutableArray arrayWithArray:results]; //firstObject is nil if results has length 0
}

- (NSManagedObject *)getCoreDataEntityWithName:(NSString *)name withObjectId:(NSString *)postObjectId withContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:name inManagedObjectContext:context];
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"objectId = %@", postObjectId]];
    [request setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:request error:&error];
    if (!results) {
        NSLog(@"Error fetching PostCoreData objects: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    return [results firstObject]; //firstObject is nil if results has length 0
}

- (void)watchPost:(PostCoreData *)postCoreData withCompletion:(void (^)(NSError *))completion {
    postCoreData.watchCount ++;
    postCoreData.watched = YES;
    
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

    PFQuery *watchQuery = [Watches query];
    [watchQuery getObjectInBackgroundWithId:postCoreData.watchObjectId block:^(PFObject * _Nullable watch, NSError * _Nullable error) {
        if (watch) {
            [watch deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error deleting watch object in server! %@", error.localizedDescription);
                    completion(error);
                } else {
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

//- (void)submitNewPost:(PostCoreData *)post withCompletion:(void (^)(NSError *))completion {
//    __weak PostManager *weakSelf = self;
//    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//        if (error != nil) {
//            NSLog(@"Post status update failed: %@", error.localizedDescription);
//            [weakSelf.allPostsArray insertObject:post atIndex:0];
//            completion(error);
//        } else {
//            completion(nil);
//        }
//    }];
//}

- (void)postListingToParseWithImage:(UIImage * _Nullable)image withCaption:(NSString * _Nullable)caption withPrice:(NSString * _Nullable)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion:(void (^)(Post *, NSError *))completion {
    //parse/server
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

- (PostCoreData *)savePostWithObjectId:(NSString *)postObjectId withImageData:(NSData * _Nullable)imageData withCaption:(NSString * _Nullable)caption withPrice:(double)price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title toCoreDataWithManagedObjectContext:(NSManagedObjectContext*)context {
    
    PostCoreData *newPost = (PostCoreData *)[self getCoreDataEntityWithName:@"PostCoreData" withObjectId:postObjectId withContext:context];
    NSLog(@"%@", newPost);
    //if post doesn't already exist in core data, then create it
    if (!newPost) {
        
        //NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"PostCoreData" inManagedObjectContext:context];
        //newPost = [[PostCoreData alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        newPost = (PostCoreData *)[NSEntityDescription insertNewObjectForEntityForName:@"PostCoreData" inManagedObjectContext:context];
        
        UserCoreData *author = (UserCoreData *)[self getCoreDataEntityWithName:@"UserCoreData" withObjectId:[PFUser currentUser].objectId withContext:context];
//        if (!author) {
//            PFUser *currentUser = [PFUser currentUser];
//            author = [self saveUserWithObjectId:currentUser.objectId withUsername:currentUser.username withEmail:currentUser.email withLocation:currentUser.locat withProfilePic:<#(NSData * _Nullable)#> toCoreDataWithManagedObjectContext:<#(nonnull NSManagedObjectContext *)#>]
//        }
        if (!newPost.author) {
            newPost.author = author;
        }
        
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
        newPost.sold = NO;
        newPost.watched = NO;
        newPost.watchCount = 0;
        newPost.price = price;
        
        NSLog(@"newpost.title %@", newPost.title);

        //save to core data persisted store
        NSError *error = nil;
        if ([context save:&error] == NO) {
         NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
    }
    NSLog(@"newpost: %@", newPost);
    return newPost;
}

- (UserCoreData *)saveUserWithObjectId:(NSString *)userObjectId withUsername:(NSString * _Nullable)username withEmail:(NSString * _Nullable)email withLocation:(NSString * _Nullable)location withProfilePic:(NSData * _Nullable)imageData toCoreDataWithManagedObjectContext:(NSManagedObjectContext*)context {
    
    UserCoreData *user = (UserCoreData *)[self getCoreDataEntityWithName:@"UserCoreData" withObjectId:userObjectId withContext:context];
    
    //if post doesn't already exist in core data, then create it
    if (!user) {
//        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"UserCoreData" inManagedObjectContext:context];
//        user = [[UserCoreData alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
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

@end
