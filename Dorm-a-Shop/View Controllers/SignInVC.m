//
//  SignInVC.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "SignInVC.h"
#import "Parse/Parse.h"
#import "AppDelegate.h"
#import "User.h"
#import "PostManager.h"

@interface SignInVC ()

@end

@implementation SignInVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)showAlertView:(NSString*)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dorm-a-Shop" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)signIn:(id)sender {
    NSString *email = self.emailField.text;
    NSString *password = self.passwordField.text;
    
    [PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *pfUser, NSError *error) {
        if (error != nil) {
            [self showAlertView:@"Unable to Sign in"];
        } else {
            [self setupCoreData];
        }
    }];
}

- (void)setupCoreData {
    [[PostManager shared] queryAllPostsWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull allPostsArray, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error querying all posts/updating core data upon app startup! %@", error.localizedDescription);
        } else {
            [[PostManager shared] queryWatchedPostsForUser:nil withCompletion:^(NSMutableArray<PostCoreData *> * _Nullable posts, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error getting watch posts/updating core data watch status");
                } else {
                    UITabBarController *tabBarController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"tabBarController"];
                    [self presentViewController:tabBarController animated:YES completion:nil];
                }
            }];
        }
    }];
    
    [[PostManager shared] queryAllUsersWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull users, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error: failed to query all users from Parse! %@", error.localizedDescription);
        }
    }];
    
    [[PostManager shared] queryConversationsFromParseWithCompletion:^(NSMutableArray<ConversationCoreData *> * _Nonnull conversations, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error: failed to query all conversations from Parse! %@", error.localizedDescription);
        }
    }];
}

@end
