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
#import "ParseManager.h"
#import "CoreDataManager.h"
#import "UserCoreData+CoreDataClass.h"

@interface SignUpVC ()

@property (readwrite, nonatomic, strong) NJOPasswordValidator *lenientValidator;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation SignUpVC

- (IBAction)tapScreen:(id)sender {
    [self->nameTextField endEditing:YES];
    [self->emailTextField endEditing:YES];
}

- (NJOPasswordValidator *)validator {
    return self.lenientValidator;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    
    locationManager = [[LocationManager alloc] init];
    
    self.lenientValidator = [NJOPasswordValidator standardValidator];
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:passwordTextField queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self updatePasswordStrength:note.object];
    }];
    
    [self updatePasswordStrength:self];
}

- (BOOL)checkFields {
    if (!nameTextField.text || nameTextField.text.length == 0) {
        [self showAlertView:@"Please Add a Name"];
        return false;
    }
    
    if (!emailTextField.text || emailTextField.text.length == 0) {
        [self showAlertView:@"Please Add an Email"];
        return false;
    }
    
    if (!passwordTextField.text || passwordTextField.text.length == 0) {
        [self showAlertView:@"Please Add a Passsword"];
        return false;
    }
    
    if (!selectedImage || selectedImage == nil) {
        [self showAlertView:@"Please Add an Image"];
        return false;
    }
    
    if (![[Utils sharedInstance] isAnEmail:emailTextField.text]) {
        [self showAlertView:@"Please Add a Valid .edu Email"];
        return false;
    }
    
    CLLocation *currentLocation = [locationManager currentLocation];
    if (currentLocation == nil) {
        [self showAlertView:@"Please Enable Location From Settings"];
        return false;
    }
    
    return true;
}

- (IBAction)signUpButtonTap:(UIButton *)sender {
    if ([self checkFields]){
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
        NSData *imageData = UIImagePNGRepresentation(selectedImage);
        PFFileObject *image = [PFFileObject fileObjectWithName:@"Profileimage.png" data:imageData];
        
        CLLocation *currentLocation = [[LocationManager sharedInstance] currentLocation];
        PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
        
        User *user = [User new];
        user.username = self->nameTextField.text;
        user.password = self->passwordTextField.text;
        user.email = self->emailTextField.text;
        user.ProfilePic = image;
        user.Location = location;
        
        __weak SignUpVC *weakSelf = self;
        [self setLocationNameForUser:user withCompletion:^(NSError *error) {
            NSString *coreDataLocation = [NSString stringWithFormat:@"(%f, %f)", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
            UserCoreData *newUser = [[CoreDataManager shared] saveUserToCoreDataWithObjectId:nil withUsername:user.username withEmail:user.email withLocation:coreDataLocation withAddress:user.address withProfilePic:imageData inRadius:YES withManagedObjectContext:weakSelf.context];
            
            [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [hud hideAnimated:YES];
                if (!error) {
                    newUser.objectId = user.objectId;
                    [weakSelf.context save:nil];
                    
                    [weakSelf setupCoreData];
                    
                    [weakSelf showAlertView:@"Welcome!"];
                    [weakSelf performSegueWithIdentifier:@"homeScreen" sender:nil];
                } else {
                    [hud hideAnimated:YES];
                    [weakSelf showAlertView:@"Someything went wrong, please try again"];
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
    currentUser.Location = selectedLocationPoint;
    
    __weak SignUpVC *weakSelf = self;
    UserCoreData *userCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:currentUser.objectId withContext:weakSelf.context];
    if (address != nil) {
        currentUser.address = address;
        userCoreData.address = address;
        [self.context save:nil];
    }
}

- (IBAction)backButtonTap:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
    selectedImage = info[UIImagePickerControllerEditedImage];
    [addPictureButton setImage:selectedImage forState:UIControlStateNormal];
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

#pragma mark -

- (void)updatePasswordStrength:(id)sender {
    NSString *password = passwordTextField.text;
    
    if ([password length] == 0) {
        self.passwordStrengthMeterView.progress = 0.0f;
    } else {
        NJOPasswordStrength strength = [NJOPasswordStrengthEvaluator strengthOfPassword:password];
        
        NSArray *failingRules = nil;
        if ([self.validator validatePassword:password failingRules:&failingRules]) {
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
    [[ParseManager shared] queryAllPostsWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull allPostsArray, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error querying all posts/updating core data upon app startup! %@", error.localizedDescription);
        } else {
            [[ParseManager shared] queryViewedPostswithCompletion:^(NSMutableArray<PostCoreData *> * _Nullable posts, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"error getting watch posts/updating core data watch status");
                }
            }];
        }
    }];
    
    [[ParseManager shared] queryAllUsersWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull users, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error: failed to query all users from Parse! %@", error.localizedDescription);
        } else {
            NSLog(@"");
        }
    }];
    
    [[ParseManager shared] queryConversationsFromParseWithCompletion:^(NSMutableArray<ConversationCoreData *> * _Nonnull conversations, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error: failed to query all conversations from Parse! %@", error.localizedDescription);
        }
    }];
}

@end
