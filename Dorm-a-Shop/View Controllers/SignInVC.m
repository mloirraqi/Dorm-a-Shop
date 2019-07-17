//
//  SignInVC.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "SignInVC.h"

@interface SignInVC ()

@end

@implementation SignInVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)signIn:(id)sender {
    
    [self performSegueWithIdentifier:@"signIn" sender:nil];
    
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
