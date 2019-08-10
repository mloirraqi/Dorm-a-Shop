//
//  EditProfileVC.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "EditProfileVC.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <GooglePlaces/GooglePlaces.h>
#import <GooglePlacePicker/GooglePlacePicker.h>
#import "Utils.h"
#import "SignInVC.h"
#import "UserCoreData+CoreDataClass.h"
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
#import "User.h"

@interface EditProfileVC () <GMSPlacePickerViewControllerDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *confirmPasswordTextField;
@property (nonatomic, weak) IBOutlet UIButton *addPictureButton;
@property (weak, nonatomic) IBOutlet UIButton *updateLocationButton;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;

@property (nonatomic, strong) PFUser *currentPFUser;

@end

@implementation EditProfileVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
}

- (void)setUpView {
    self.submitButton.hidden = true;
    
    self.currentPFUser = PFUser.currentUser;
    self.nameTextField.text = self.user.username;
    self.emailTextField.text = self.user.email;
    self.locationLabel.text = self.user.address;
    self.passwordTextField.placeholder = @"New password";
    self.confirmPasswordTextField.placeholder = @"Confirm new password";
    
    self.nameTextField.delegate = self;
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.confirmPasswordTextField.delegate = self;

    self.submitButton.layer.cornerRadius = 5;
    self.submitButton.layer.borderWidth = 1.0f;
    self.submitButton.layer.borderColor = [UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:1].CGColor;
    self.submitButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    
    NSData *imageData = self.user.profilePic;
    [self.addPictureButton setImage:[UIImage imageWithData:imageData] forState:UIControlStateNormal];
}

- (BOOL)checkFields {
    if (!self.nameTextField.text || self.nameTextField.text.length == 0) {
        [self showAlertView:@"Please add Name First"];
        return false;
    }
    
    if (!self.emailTextField.text || self.emailTextField.text.length == 0) {
        [self showAlertView:@"Please add Email First"];
        return false;
    }
    
    if (self.passwordTextField.text != self.confirmPasswordTextField.text) {
        [self showAlertView:@"Passwords Don't Match"];
        return false;
    }
    
    if (![[Utils sharedInstance] isAnEmail:self.emailTextField.text]) {
        [self showAlertView:@"Please add correct Email"];
        return false;
    }
    
    if (![[Utils sharedInstance] isValidEmail:self.emailTextField.text]) {
        [self showAlertView:@"Please add correct Email"];
        return false;
    }
    
    return true;
}


- (void)showAlertView:(NSString*)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dorm-a-Shop"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)textValuesChanged:(id)sender {
    [self submitButtonUpdateVisibility];
}

- (void)submitButtonUpdateVisibility {
    if (self.nameTextField.text.length != 0 && self.nameTextField.text != self.self.user.username){
        self.submitButton.hidden = false;
    } else if (self.emailTextField.text.length != 0 && self.emailTextField.text != self.user.email){
        self.submitButton.hidden = false;
    } else if (self.passwordTextField.text.length != 0 && self.confirmPasswordTextField.text != 0){
        self.submitButton.hidden = false;
    } else if (self.selectedImage != nil) {
        self.submitButton.hidden = false;
    } else if (self.selectedLocationPoint != nil) {
        self.submitButton.hidden = false;
    } else {
        self.submitButton.hidden = true;
    }
}

- (IBAction)submitButtonAction:(UIButton *)sender {
    if ([self checkFields]){
        [MBProgressHUD showHUDAddedTo:self.view animated:true];
        self.user.username = self.nameTextField.text;
        self.user.email = self.emailTextField.text;
        
        self.currentPFUser.username = self.nameTextField.text;
        self.currentPFUser.email = self.emailTextField.text;
        
        if (self.passwordTextField.text.length != 0) {
            self.currentPFUser.password = self.passwordTextField.text;
        }
        
        if (self.selectedImage != nil) {
            NSData *imageData = UIImagePNGRepresentation(self.selectedImage);
            PFFileObject *image = [PFFileObject fileObjectWithName:@"Profileimage.png" data:imageData];
            [image saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"Error saving new profile pic to parse! %@", error.localizedDescription);
                }
            }];
            self.currentPFUser[@"ProfilePic"] = image;
            self.user.profilePic = imageData;
        }
        
        if (self.selectedLocationPoint != nil) {
            [self setLocationName];
        }
        
        __weak EditProfileVC *weakSelf = self;
        [PFUser.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [MBProgressHUD hideHUDForView:weakSelf.view animated:true];
            if (!error) {
                [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
                    return YES;
                } withName:[NSString stringWithFormat:@"%@", weakSelf.user.objectId]];
                //        [self saveContext];
                
                [weakSelf.delegate updateEditProfileData:weakSelf];
                
                UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Your update of the profile is successful!" preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                }];
                [successAlert addAction:okAction];
                [self presentViewController:successAlert animated:YES completion:nil];
            } else {
                NSString *errorString = [error userInfo][@"error"];
                [self showAlertView:errorString];
            }
        }];
    }
}

- (void)setLocationName {
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:self.selectedLocationPoint.latitude longitude:self.selectedLocationPoint.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    __weak EditProfileVC *weakSelf = self;
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        
        NSString *strAdd = nil;
        
        if (error == nil && [placemarks count] > 0) {
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
        
        if (strAdd != nil) {
            self.currentPFUser[@"address"] = strAdd;
            self.user.address = strAdd;
        }
        
        self.currentPFUser[@"Location"] = weakSelf.selectedLocationPoint;
    }];
}

- (IBAction)updateLocationButtonAction:(UIButton *)sender {
    GMSPlacePickerConfig *config = [[GMSPlacePickerConfig alloc] initWithViewport:nil];
    GMSPlacePickerViewController *placePicker =
    [[GMSPlacePickerViewController alloc] initWithConfig:config];
    placePicker.delegate = self;
    
    [self presentViewController:placePicker animated:YES completion:nil];
}

- (IBAction)editPictureButtonTap:(UIButton *)sender {
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
    [self submitButtonUpdateVisibility];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

// To receive the results from the place picker 'self' will need to conform to
// GMSPlacePickerViewControllerDelegate and implement this code.
- (void)placePicker:(GMSPlacePickerViewController *)viewController didPickPlace:(GMSPlace *)place {
    // Dismiss the place picker, as it cannot dismiss itself.
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    self.locationLabel.text = place.formattedAddress;
    self.locationSelected = YES;
    self.selectedLocationPoint = [PFGeoPoint geoPointWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];
    [self submitButtonUpdateVisibility];
}

- (void)placePickerDidCancel:(GMSPlacePickerViewController *)viewController {
    // Dismiss the place picker, as it cannot dismiss itself.
    [viewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"No place selected");
}

- (void)saveContext {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

- (IBAction)onTap:(id)sender {
    [self.nameTextField endEditing:YES];
    [self.passwordTextField endEditing:YES];
    [self.emailTextField endEditing:YES];
    [self.confirmPasswordTextField endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end

