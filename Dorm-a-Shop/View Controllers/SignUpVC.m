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
#import "PostManager.h"


@interface SignUpVC ()

@property (readwrite, nonatomic, strong) NJOPasswordValidator *lenientValidator;

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
    locationManager = [[LocationManager alloc]init];
    
    self.lenientValidator = [NJOPasswordValidator standardValidator];
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:passwordTextField queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self updatePasswordStrength:note.object];
    }];
    
    [self updatePasswordStrength:self];

}

- (BOOL)checkFields {
    if (!nameTextField.text || nameTextField.text.length == 0){
        [self showAlertView:@"Please Add a Name"];
        return false;
    }
    if (!emailTextField.text || emailTextField.text.length == 0){
        [self showAlertView:@"Please Add an Email"];
        return false;
    }
    if (!passwordTextField.text || passwordTextField.text.length == 0){
        [self showAlertView:@"Please Add a Passsword"];
        return false;
    }
    if (!selectedImage || selectedImage == nil){
        [self showAlertView:@"Please Add an Image"];
        return false;
    }
    if (![[Utils sharedInstance] isAnEmail:emailTextField.text]){
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
        
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
        NSString *coreDataLocation = [NSString stringWithFormat:@"(%f, %f)", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
        UserCoreData *newUser = [[PostManager shared] saveUserToCoreDataWithObjectId:nil withUsername:user.username withEmail:user.email withLocation:coreDataLocation withProfilePic:imageData withManagedObjectContext:context];
        
        __weak SignUpVC *weakSelf = self;
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [hud hideAnimated:YES];
            if (!error) {
                newUser.objectId = user.objectId;
                [weakSelf showAlertView:@"Welcome!"];
                [weakSelf performSegueWithIdentifier:@"homeScreen" sender:nil];
            } else {
                [hud hideAnimated:YES];
                [weakSelf showAlertView:@"Someything went wrong, please try again"];
                NSLog(@"😫😫😫, error: %@", error.localizedDescription);
            }
        }];
    }
}

- (void)setLocationName {
    CLLocation *currentLocation = [[LocationManager sharedInstance] currentLocation];
    PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
//        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        
        NSString *strAdd = nil;
        
        if (error == nil && [placemarks count] > 0)
        {
            CLPlacemark *placemark = [placemarks lastObject];
            
            // strAdd -> take bydefault value nil
            
            
            if ([placemark.subThoroughfare length] != 0)
                strAdd = placemark.subThoroughfare;
            
            if ([placemark.thoroughfare length] != 0)
            {
                // strAdd -> store value of current location
                if ([strAdd length] != 0)
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark thoroughfare]];
                else
                {
                    // strAdd -> store only this value,which is not null
                    strAdd = placemark.thoroughfare;
                }
            }
            
            if ([placemark.postalCode length] != 0)
            {
                if ([strAdd length] != 0)
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark postalCode]];
                else
                    strAdd = placemark.postalCode;
            }
            
            if ([placemark.locality length] != 0)
            {
                if ([strAdd length] != 0)
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark locality]];
                else
                    strAdd = placemark.locality;
            }
            
            if ([placemark.administrativeArea length] != 0)
            {
                if ([strAdd length] != 0)
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark administrativeArea]];
                else
                    strAdd = placemark.administrativeArea;
            }
            
            if ([placemark.country length] != 0)
            {
                if ([strAdd length] != 0)
                    strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark country]];
                else
                    strAdd = placemark.country;
            }
            
//            NSLog(@"%@", strAdd);
        }
        
        [self updateLocationWith:strAdd location:location];
    }];
}

- (void)updateLocationWith:(NSString *)address location:(PFGeoPoint *)location {
    PFUser *currentUser = [PFUser currentUser];
    currentUser[@"Location"] = location;
    if(address != nil)
    {
        currentUser[@"address"] = address;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:true];
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        [MBProgressHUD hideHUDForView:self.view animated:true];
        if (!error) {
            // Hooray! Let them use the app now.
            [self showAlertView:@"Welcome!"];
            [self performSegueWithIdentifier:@"homeScreen" sender:nil];
            
        } else {
            NSString *errorString = [error userInfo][@"error"];
            [self showAlertView:errorString];
            // Show the errorString somewhere and let the user try again.
        }
    }];
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

@end
