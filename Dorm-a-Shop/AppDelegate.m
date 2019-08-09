//
//  AppDelegate.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import <GooglePlaces/GooglePlaces.h>
#import <GooglePlacePicker/GooglePlacePicker.h>
#import <GoogleMaps/GoogleMaps.h>
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
#import "User.h"
#import "LocationManager.h"
@import Parse;
@import IQKeyboardManager;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [LocationManager sharedInstance];
    
    [GMSServices provideAPIKey:@"AIzaSyC1sOYEZLpUFrZgeclrwGG5UzpJ57erHg4"];
    [GMSPlacesClient provideAPIKey:@"AIzaSyCQq014wwF0Stjx8gfDIUW3TxYfBuXCDD8"];

    ParseClientConfiguration *config = [ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.applicationId = @"dormAshop";
        configuration.server = @"https://dorm-a-shop.herokuapp.com/parse";
        configuration.clientKey = @"Heroku";
    }];
    
    [Parse initializeWithConfiguration:config];
    
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];

    if (PFUser.currentUser) {
        [[ParseDatabaseManager shared] queryAllPostsWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull allPostsArray, NSMutableArray * _Nonnull hotArray, NSError * _Nonnull error) {
            if (error) {
                NSLog(@"Error querying all posts/updating core data upon app startup! %@", error.localizedDescription);
            } else {
                [[CoreDataManager shared] enqueueDoneSavingPostsWatches];
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"tabBarController"];
                NSLog(@"");
            }
        }];
        
        [[ParseDatabaseManager shared] queryAllUsersWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull users, NSError * _Nonnull error) {
            if (error) {
                NSLog(@"Error: failed to query all users from Parse! %@", error.localizedDescription);
            } else {
                [[CoreDataManager shared] enqueueDoneSavingUsers];
            }
        }];

        
        [[ParseDatabaseManager shared] queryConversationsFromParseWithCompletion:^(NSMutableArray<ConversationCoreData *> * _Nonnull conversations, NSError * _Nonnull error) {
            if (error) {
                NSLog(@"Error: failed to query all conversations from Parse! %@", error.localizedDescription);
            } else {
                [[CoreDataManager shared] enqueueDoneSavingConversations];
            }
        }];

        [[ParseDatabaseManager shared] queryReviewsForSeller:nil withCompletion:^(NSMutableArray * _Nonnull reviewsArray, NSError * _Nonnull error) {
            if (error) {
                NSLog(@"Error: failed to query all reviews for user from Parse! %@", error.localizedDescription);
            } else {
                [[CoreDataManager shared] enqueueDoneSavingReviews];
            }
        }];
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignInVC"];
        NSLog(@"");
        
        NSFetchRequest *requestConversations = [[NSFetchRequest alloc] initWithEntityName:@"ConversationCoreData"];
        NSBatchDeleteRequest *deleteConversations = [[NSBatchDeleteRequest alloc] initWithFetchRequest:requestConversations];
        NSError *deleteConversationsError = nil;
        [self.persistentContainer.viewContext executeRequest:deleteConversations error:&deleteConversationsError];
        
        NSFetchRequest *requestUsers = [[NSFetchRequest alloc] initWithEntityName:@"UserCoreData"];
        NSBatchDeleteRequest *deleteUsers = [[NSBatchDeleteRequest alloc] initWithFetchRequest:requestUsers];
        NSError *deleteUsersError = nil;
        [self.persistentContainer.viewContext executeRequest:deleteUsers error:&deleteUsersError];
        
        NSFetchRequest *requestPosts = [[NSFetchRequest alloc] initWithEntityName:@"PostCoreData"];
        NSBatchDeleteRequest *deletePosts = [[NSBatchDeleteRequest alloc] initWithFetchRequest:requestPosts];
        NSError *deletePostsError = nil;
        [self.persistentContainer.viewContext executeRequest:deletePosts error:&deletePostsError];
        
        NSFetchRequest *requestReviews = [[NSFetchRequest alloc] initWithEntityName:@"ReviewCoreData"];
        NSBatchDeleteRequest *deleteReviews = [[NSBatchDeleteRequest alloc] initWithFetchRequest:requestReviews];
        NSError *deleteReviewsError = nil;
        [self.persistentContainer.viewContext executeRequest:deleteReviews error:&deleteReviewsError];
    }
    
    [IQKeyboardManager sharedManager].enable = YES;
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;
//@synthesize managedObjectContext = _managedObjectContext;

- (NSPersistentContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it. This way you can access the persistent container anywhere since you can access AppDelegate from anywhere (similar for saveContext)
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"DormAShop"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    _persistentContainer.viewContext.mergePolicy = NSMergePolicy.overwriteMergePolicy;
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
    [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
        return YES;
    } withName:@""];
}


@end
