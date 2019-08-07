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

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation EditProfileVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
}

- (void)setUpView {
    submitButton.hidden = true;
    
    PFUser *currentUser = [PFUser currentUser];
    [currentUser fetch];
    
    nameTextField.text = currentUser.username;
    emailTextField.text = currentUser.email;
    passwordTextField.text = currentUser.password;
    
    nameTextField.delegate = self;
    emailTextField.delegate = self;
    passwordTextField.delegate = self;
    confirmPasswordTextField.delegate = self;
    
    PFFileObject *image = currentUser[@"ProfilePic"];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    
    [image getDataInBackgroundWithBlock:^(NSData *_Nullable data, NSError * _Nullable error) {
        UIImage *originalImage = [UIImage imageWithData:data];
        [self->addPictureButton setImage:originalImage forState:UIControlStateNormal];
    }];
}

- (BOOL)checkFields {
    if (!nameTextField.text || nameTextField.text.length == 0) {
        [self showAlertView:@"Please add Name First"];
        return false;
    }
    if (!emailTextField.text || emailTextField.text.length == 0) {
        [self showAlertView:@"Please add Email First"];
        return false;
    }
    
    if (passwordTextField.text != confirmPasswordTextField.text) {
        [self showAlertView:@"Passwords Don't Match"];
        return false;
    }
    
    if (![[Utils sharedInstance] isAnEmail:emailTextField.text]) {
        [self showAlertView:@"Please add correct Email"];
        return false;
    }
    
    if (![[Utils sharedInstance] isValidEmail:emailTextField.text]) {
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
    [self submitButtonUpdate];
}

- (void)submitButtonUpdate {
    PFUser *currentUser = [PFUser currentUser];
    
    if (nameTextField.text.length != 0 && nameTextField.text != currentUser.username){
        submitButton.hidden = false;
    } else if (emailTextField.text.length != 0 && emailTextField.text != currentUser.email){
        submitButton.hidden = false;
    } else if (passwordTextField.text.length != 0 && confirmPasswordTextField.text != 0){
        submitButton.hidden = false;
    } else if (selectedImage != nil) {
        submitButton.hidden = false;
    } else if (selectedLocationPoint != nil) {
        submitButton.hidden = false;
    } else {
        submitButton.hidden = true;
    }
}


- (IBAction)editProfileButtonAction:(UIButton *)sender {
    if ([self checkFields]){
        PFUser *currentUser = [PFUser currentUser];
        currentUser.username = nameTextField.text;
        currentUser.email = emailTextField.text;
        
        if (passwordTextField.text.length != 0) {
            currentUser.password = passwordTextField.text;
        }
        
        if (selectedImage != nil) {
            NSData *imageData = UIImagePNGRepresentation(selectedImage);
            PFFileObject *image = [PFFileObject fileObjectWithName:@"Profileimage.png" data:imageData];
            [image saveInBackground];
            currentUser[@"ProfilePic"] = image;
        }
        
        [MBProgressHUD showHUDAddedTo:self.view animated:true];
        [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [MBProgressHUD hideHUDForView:self.view animated:true];
            if (!error) {
                //Let users use app now
                if (self->selectedLocationPoint != nil) {
                    [self setLocationName];
                }
                else
                {
                    UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Your update of the profile is successful!" preferredStyle:(UIAlertControllerStyleAlert)];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self.navigationController popViewControllerAnimated:YES];
                    }];
                    [successAlert addAction:okAction];
                    [self presentViewController:successAlert animated:YES completion:nil];
                }
                
            } else {
                NSString *errorString = [error userInfo][@"error"];
                [self showAlertView:errorString];
                // Show the errorString somewhere and let the user try again.
            }
        }];
    }
}

- (void)setLocationName {
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:selectedLocationPoint.latitude longitude:selectedLocationPoint.longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
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
        
        [self updateLocationWith:strAdd];
    }];
}

- (void)updateLocationWith:(NSString *)address {
    User *currentUser = (User *)[PFUser currentUser];
    currentUser.Location = selectedLocationPoint;
    
    UserCoreData *userCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:currentUser.objectId withContext:self.context];
    if (address != nil) {
        currentUser.address = address;
        userCoreData.address = address;
        
//        [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
//            return YES;
//        } withName:[NSString stringWithFormat:@"%@", userCoreData.objectId]];
        [self saveContext];
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:true];
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        [MBProgressHUD hideHUDForView:self.view animated:true];
        if (!error) {
            
            UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"Success" message:@"Your update of the profile is successful!" preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
            [successAlert addAction:okAction];
            [self presentViewController:successAlert animated:YES completion:nil];
            
        } else {
            NSString *errorString = [error userInfo][@"error"];
            [self showAlertView:errorString];
        }
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
    selectedImage = info[UIImagePickerControllerEditedImage];
    [addPictureButton setImage:selectedImage forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self submitButtonUpdate];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

// To receive the results from the place picker 'self' will need to conform to
// GMSPlacePickerViewControllerDelegate and implement this code.
- (void)placePicker:(GMSPlacePickerViewController *)viewController didPickPlace:(GMSPlace *)place {
    // Dismiss the place picker, as it cannot dismiss itself.
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    [updateLocationButton setTitle:place.formattedAddress forState:UIControlStateNormal];
    locationSelected = YES;
    selectedLocationPoint = [PFGeoPoint geoPointWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];
    [self submitButtonUpdate];
}

- (void)placePickerDidCancel:(GMSPlacePickerViewController *)viewController {
    // Dismiss the place picker, as it cannot dismiss itself.
    [viewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"No place selected");
}

- (void)saveContext {
    NSError *error = nil;
    if ([self.context hasChanges] && ![self.context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

- (IBAction)onTap:(id)sender {
    [self->nameTextField endEditing:YES];
    [self->passwordTextField endEditing:YES];
    [self->emailTextField endEditing:YES];
    [self->confirmPasswordTextField endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}


@end

