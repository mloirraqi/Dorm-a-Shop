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
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"

@interface SignInVC () <UITextFieldDelegate>

@end

@implementation SignInVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.passwordField.delegate = self;
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
    [[ParseDatabaseManager shared] queryAllPostsWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull allPostsArray, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error querying all posts/updating core data upon app startup! %@", error.localizedDescription);
        } else {
            [self performSegueWithIdentifier:@"signIn" sender:nil];
//            [[CoreDataManager shared] enqueueDoneSavingPostsWatches];
        }
    }];
    
    [[ParseDatabaseManager shared] queryAllUsersWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull users, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error: failed to query all users from Parse! %@", error.localizedDescription);
        } else {
//            [[CoreDataManager shared] enqueueDoneSavingUsers];
        }
    }];
    
    
    [[ParseDatabaseManager shared] queryConversationsFromParseWithCompletion:^(NSMutableArray<ConversationCoreData *> * _Nonnull conversations, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error: failed to query all conversations from Parse! %@", error.localizedDescription);
        } else {
//            [[CoreDataManager shared] enqueueDoneSavingConversations];
        }
    }];
    
    [[ParseDatabaseManager shared] queryReviewsForSeller:nil withCompletion:^(NSMutableArray * _Nonnull reviewsArray, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error: failed to query all reviews for user from Parse! %@", error.localizedDescription);
        } else {
//            [[CoreDataManager shared] enqueueDoneSavingReviews];
        }
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailField) {
        [textField resignFirstResponder];
        return NO;
    } else {
        [self signIn:nil];
    }
    return YES;
}

- (IBAction)onTap:(id)sender {
    [self.emailField endEditing:YES];
    [self.passwordField endEditing:YES];
}


@end
