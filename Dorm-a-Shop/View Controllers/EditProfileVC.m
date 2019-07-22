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

@interface EditProfileVC ()

@end

@implementation EditProfileVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpView];
}

- (void)setUpView {
    PFUser *currentUser = [PFUser currentUser];
    [currentUser fetch];
    nameTextField.text = currentUser.username;
    emailTextField.text = currentUser.email;
    
    PFFileObject *image = currentUser[@"ProfilePic"];
    [image getDataInBackgroundWithBlock:^(NSData *_Nullable data, NSError * _Nullable error){
        UIImage *originalImage = [UIImage imageWithData:data];
        [addPictureButton setImage:originalImage forState:UIControlStateNormal];
    }];
    confirmPasswordTextField.hidden = YES;
    passwordTextField.hidden = YES;
    }

- (BOOL)checkFields{
    if (!nameTextField.text || nameTextField.text.length == 0){
        [self showAlertView:@"Please add Name First"];
        return false;
    }
    if (!emailTextField.text || emailTextField.text.length == 0){
        [self showAlertView:@"Please add Email First"];
        return false;
    }
    if(passwordTextField.text.length == 0){
        [self showAlertView:@"Please add Password First"];
        return false;
    }
    
    if (passwordTextField.text != confirmPasswordTextField.text){
        [self showAlertView:@"Passwords Don't Match"];
        return false;
    }
    
    if (![[Utils sharedInstance] isAnEmail:emailTextField.text]){
        [self showAlertView:@"Please add correct Email"];
        return false;
    }
    if (![[Utils sharedInstance] isValidEmail:emailTextField.text]){
        [self showAlertView:@"Please add correct Email"];
        return false;
    }
    
    return true;
}


-(void)showAlertView:(NSString*)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dorm-a-Shop"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)changePasswordShow:(id)sender {
    passwordTextField.hidden = NO;
    confirmPasswordTextField.hidden = NO;
}


- (IBAction)editProfileButtonAction:(UIButton *)sender {
    if ([self checkFields]){
        PFUser *currentUser = [PFUser currentUser];
        currentUser.username = nameTextField.text;
        currentUser.email = emailTextField.text;
        
        //        if(passwordTextField.text == @""){
        //        currentUser.password = passwordField.text;
        //        }
        //        else currentUser.password = passwordTextField.text;
        
        if (selectedImage != nil)
        {
            NSData *imageData = UIImagePNGRepresentation(selectedImage);
            PFFileObject *image = [PFFileObject fileObjectWithName:@"Profileimage.png" data:imageData];
            [image saveInBackground];
            currentUser[@"ProfilePic"] = image;
        }
        
        if (selectedLocationPoint != nil) {
            currentUser[@"Location"] = self->selectedLocationPoint;
        }
        
        [MBProgressHUD showHUDAddedTo:self.view animated:true];
        [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [MBProgressHUD hideHUDForView:self.view animated:true];
            if (!error) {
                // Hooray! Let them use the app now.
                [self showAlertView:@"Updated Successfully"];
            } else {
                NSString *errorString = [error userInfo][@"error"];
                [self showAlertView:errorString];
                // Show the errorString somewhere and let the user try again.
            }
        }];
}
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
        
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:picker animated:YES completion:NULL];
        
        [alertController dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertController addAction:takePhoto];
    
    UIAlertAction *choosePhoto=[UIAlertAction actionWithTitle:@"Select From Photos" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIImagePickerController *pickerView = [[UIImagePickerController alloc] init];
        
        pickerView.allowsEditing = YES;
        
        pickerView.delegate = self;
        
        [pickerView setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        
        [self presentModalViewController:pickerView animated:YES];
        
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


// To receive the results from the place picker 'self' will need to conform to
// GMSPlacePickerViewControllerDelegate and implement this code.
- (void)placePicker:(GMSPlacePickerViewController *)viewController didPickPlace:(GMSPlace *)place {
    // Dismiss the place picker, as it cannot dismiss itself.
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"Place name %@", place.name);
    NSLog(@"Place address %@", place.formattedAddress);
    NSLog(@"Place attributions %@", place.attributions.string);
    
    [updateLocationButton setTitle:place.formattedAddress forState:UIControlStateNormal];
    locationSelected = YES;
    selectedLocationPoint = [PFGeoPoint geoPointWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];
}

- (void)placePickerDidCancel:(GMSPlacePickerViewController *)viewController {
    // Dismiss the place picker, as it cannot dismiss itself.
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"No place selected");
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
