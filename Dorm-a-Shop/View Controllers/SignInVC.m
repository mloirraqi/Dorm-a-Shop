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

-(void)showAlertView:(NSString*)message{
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
            User *user = (User *)pfUser;
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
            NSString *location = [NSString stringWithFormat:@"(%f, %f)", user.Location.latitude, user.Location.longitude];
            
            UserCoreData *userCoreData = [[PostManager shared] saveUserToCoreDataWithObjectId:user.objectId withUsername:user.username withEmail:user.email withLocation:location withProfilePic:nil withManagedObjectContext:context];
            
            [user.ProfilePic getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                //set image later
                if (data) {
                    userCoreData.profilePic = data;
        
                    //save updated attribute to managed object context
                    [context save:nil];
                } else {
                    NSLog(@"error updating postCoreData image! %@", error.localizedDescription);
                }
            }];
            
            UITabBarController *tabBarController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"tabBarController"];
            
            [self presentViewController:tabBarController animated:YES completion:nil];
        }
    }];
}

@end
