//
//  SignUpVC.m
//  DormAShop
//
//  Created by mloirraqi on 7/12/19.
//  Copyright © 2019 mloirraqi. All rights reserved.
//

#import "SignUpVC.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "Utils.h"
#import "User.h"
#import "NJOPasswordStrengthEvaluator.h"
#import <Parse/Parse.h>
#import "HomeScreenViewController.h"
#import "LocationManager.h"
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
#import "UserCoreData+CoreDataClass.h"

@interface SignUpVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic) IBOutlet UIProgressView *passwordStrengthMeterView;
@property (weak, nonatomic) IBOutlet UIButton *addPictureButton;

@property (strong, nonatomic) PFGeoPoint *selectedLocationPoint;
@property (strong, nonatomic) UIImage *selectedImage;
@property (strong, nonatomic) LocationManager *locationManager;
@property (strong, nonatomic) MBProgressHUD *hud;

@property (readwrite, nonatomic, strong) NJOPasswordValidator *lenientValidator;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation SignUpVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.nameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.emailTextField.delegate = self;
    
    self.selectedImage = [UIImage imageNamed:@"profile-default"];
    
    self.appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = self.appDelegate.persistentContainer.viewContext;
    
    self.locationManager = [[LocationManager alloc] init];
    
    self.lenientValidator = [NJOPasswordValidator standardValidator];
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:self.passwordTextField queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self updatePasswordStrength:note.object];
    }];
    
    [self updatePasswordStrength:self];
}

- (BOOL)checkFields {
    if (!self.nameTextField.text || self.nameTextField.text.length == 0) {
        [self showAlertView:@"Please Add a Name"];
        return false;
    }
    
    if (!self.emailTextField.text || self.emailTextField.text.length == 0) {
        [self showAlertView:@"Please Add an Email"];
        return false;
    }
    
    if (!self.passwordTextField.text || self.passwordTextField.text.length == 0) {
        [self showAlertView:@"Please Add a Passsword"];
        return false;
    }
    
    if (![[Utils sharedInstance] isAnEmail:self.emailTextField.text]) {
        [self showAlertView:@"Please Add a Valid .edu Email"];
        return false;
    }
    
    CLLocation *currentLocation = [self.locationManager currentLocation];
    if (currentLocation == nil) {
        [self showAlertView:@"Please Enable Location From Settings"];
        return false;
    }
    
    return true;
}

- (IBAction)signUpButtonTap:(id)sender {
    if ([self checkFields]){
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
        self.hud.label.text = @"Signing up ...";
        NSData *imageData = UIImagePNGRepresentation(self.selectedImage);
        PFFileObject *image = [PFFileObject fileObjectWithName:@"Profileimage.png" data:imageData];
        
        CLLocation *currentLocation = [[LocationManager sharedInstance] currentLocation];
        PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
        
        User *user = [User new];
        user.username = self.nameTextField.text;
        user.password = self.passwordTextField.text;
        user.email = self.emailTextField.text;
        user.ProfilePic = image;
        user.Location = location;
        
        __weak SignUpVC *weakSelf = self;
        [self setLocationNameForUser:user withCompletion:^(NSError *error) {
            NSString *coreDataLocation = [NSString stringWithFormat:@"(%f, %f)", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
            UserCoreData *newUser = [[CoreDataManager shared] saveUserToCoreDataWithObjectId:nil withUsername:user.username withLocation:coreDataLocation withAddress:user.address withProfilePic:imageData inRadius:YES withManagedObjectContext:weakSelf.context];
            
            [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [weakSelf.hud hideAnimated:YES];
                if (!error) {
                    newUser.objectId = user.objectId;
                    [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
                        return YES;
                    } withName:newUser.objectId];
//                    [self saveContext];                    
                    [weakSelf setupCoreData];
                } else {
                    [weakSelf.hud hideAnimated:YES];
                    [weakSelf showAlertView:[NSString stringWithFormat:@"Something went wrong: %@. Please try again.", error.localizedDescription]];
                    NSLog(@"😫😫😫, error: %@", error.localizedDescription);
                }
            }];
        }];
    }
}

- (void)setLocationNameForUser:(User *)user withCompletion:(void (^)(NSError *))completion {
    CLLocation *currentLocation = [[LocationManager sharedInstance] currentLocation];
    PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        NSString *strAdd = nil;
        
        if (error == nil && [placemarks count] > 0)
        {
            CLPlacemark *placemark = [placemarks lastObject];
            
            // strAdd -> take bydefault value nil
            
            if ([placemark.subThoroughfare length] != 0) {
                strAdd = placemark.subThoroughfare;
            }
            
            if ([placemark.thoroughfare length] != 0) {
                // strAdd -> store value of current location
                if ([strAdd length] != 0) {
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark thoroughfare]];
                } else {
                    // strAdd -> store only this value,which is not null
                    strAdd = placemark.thoroughfare;
                }
            }
            
            if ([placemark.postalCode length] != 0) {
                if ([strAdd length] != 0) {
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark postalCode]];
                } else {
                    strAdd = placemark.postalCode;
                }
            }
            
            if ([placemark.locality length] != 0) {
                if ([strAdd length] != 0) {
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark locality]];
                } else {
                    strAdd = placemark.locality;
                }
            }
            
            if ([placemark.administrativeArea length] != 0) {
                if ([strAdd length] != 0) {
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark administrativeArea]];
                } else {
                    strAdd = placemark.administrativeArea;
                }
            }
            
            if ([placemark.country length] != 0) {
                if ([strAdd length] != 0) {
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark country]];
                } else {
                    strAdd = placemark.country;
                }
            }
        }
        
        user.address = strAdd;
        user.Location = location;
        completion(nil);
    }];
}

- (void)updateLocationWith:(NSString *)address location:(PFGeoPoint *)location {
    User *currentUser = (User *)[PFUser currentUser];
    currentUser.Location = self.selectedLocationPoint;
    
    __weak SignUpVC *weakSelf = self;
    UserCoreData *userCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:currentUser.objectId withContext:weakSelf.context];
    if (address != nil) {
        currentUser.address = address;
        userCoreData.address = address;
        
        [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
            return YES;
        } withName:userCoreData.objectId];
//        [self saveContext];
    }
}

- (IBAction)pictureButtonTap:(UIButton *)sender {
    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:@"" message:@"Choose image" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *takePhoto=[UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        
        [self presentViewController:picker animated:YES completion:NULL];
        [alertController dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertController addAction:takePhoto];
    
    UIAlertAction *choosePhoto=[UIAlertAction actionWithTitle:@"Select From Photos" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *pickerView = [[UIImagePickerController alloc] init];
        pickerView.allowsEditing = YES;
        pickerView.delegate = self;
        [pickerView setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        
        [self presentViewController:pickerView animated:YES completion:nil];
        [alertController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alertController addAction:choosePhoto];
    
    UIAlertAction *actionCancel=[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        [alertController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.selectedImage = info[UIImagePickerControllerEditedImage];
    [self.addPictureButton setImage:self.selectedImage forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)showAlertView:(NSString*)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dorm-a-Shop"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
}

- (void)updatePasswordStrength:(id)sender {
    NSString *password = self.passwordTextField.text;
    
    if ([password length] == 0) {
        self.passwordStrengthMeterView.progress = 0.0f;
    } else {
        NJOPasswordStrength strength = [NJOPasswordStrengthEvaluator strengthOfPassword:password];
        
        NSArray *failingRules = nil;
        if ([self.lenientValidator validatePassword:password failingRules:&failingRules]) {
            switch (strength) {
                case NJOVeryWeakPasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.15f;
                    self.passwordStrengthMeterView.progressTintColor = [UIColor redColor];
                    break;
                case NJOWeakPasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.35f;
                    self.passwordStrengthMeterView.progressTintColor = [UIColor orangeColor];
                    break;
                case NJOReasonablePasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.5f;
                    self.passwordStrengthMeterView.progressTintColor = [UIColor yellowColor];
                    break;
                case NJOStrongPasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.75f;
                    self.passwordStrengthMeterView.progressTintColor = [UIColor greenColor];
                    break;
                case NJOVeryStrongPasswordStrength:
                    self.passwordStrengthMeterView.progress = 1.0f;
                    self.passwordStrengthMeterView.progressTintColor = [UIColor cyanColor];
                    break;
            }
        } else {
            self.passwordStrengthMeterView.progress = 0.15f;
            self.passwordStrengthMeterView.progressTintColor = [UIColor redColor];
            
            NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
            for (id <NJOPasswordRule> rule in failingRules) {
                [mutableAttributedString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"• %@\n", [rule localizedErrorDescription]] attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}]];
            }
        }
    }
}

- (void)setupCoreData {
    __weak SignUpVC *weakSelf = self;
    [[ParseDatabaseManager shared] queryAllPostsWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull allPostsArray, NSMutableArray * _Nonnull hotArray, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error querying all posts/updating core data upon app startup! %@", error.localizedDescription);
        } else {
            [weakSelf showAlertView:@"Welcome!"];
            [weakSelf performSegueWithIdentifier:@"signUp" sender:nil];
            [weakSelf.hud hideAnimated:YES];
            [[CoreDataManager shared] enqueueDoneSavingPostsWatches];
        }
    }];
    
    [[ParseDatabaseManager shared] queryAllUsersWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull users, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error: failed to query all users from Parse! %@", error.localizedDescription);
        } else {
//            for (UserCoreData *userc in users) {
//                NSLog(@"before fetch, from completion: %@ %@", userc.username, userc.objectId);
//            }
//
//            NSMutableArray *userArray = [[CoreDataManager shared] getAllUsersInRadiusFromCoreData];
//            NSLog(@"after fetch: %@", userArray);
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
}

- (void)saveContext {
    NSError *error = nil;
    if ([self.context hasChanges] && ![self.context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameTextField || textField == self.emailTextField) {
        [textField resignFirstResponder];
        return NO;
    } else {
        [self signUpButtonTap:nil];
    }
    return YES;
}


- (IBAction)onTap:(id)sender {
    [self.nameTextField endEditing:YES];
    [self.passwordTextField endEditing:YES];
    [self.emailTextField endEditing:YES];
}

- (IBAction)backtoSignin:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
