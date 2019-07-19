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

@interface SignInVC ()

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation SignInVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)showAlertView:(NSString*)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dorm-a-Shop"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
}

- (IBAction)signIn:(id)sender {
    
    NSString *email = self.emailField.text;
    NSString *password = self.passwordField.text;
    
    [PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error) {
        if (error != nil) {
            [self showAlertView:@"Unable to Sign in"];
        } else {
            NSLog(@"User logged in successfully");
            UITabBarController *tabBarController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"tabBarController"];
            
            [self presentViewController:tabBarController animated:YES completion:nil];
        }
    }];
    
//    [self performSegueWithIdentifier:@"signIn" sender:nil];
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
