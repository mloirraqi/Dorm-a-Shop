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
#import "NJOPasswordStrengthEvaluator.h"
#import <Parse/Parse.h>
#import "HomeScreenViewController.h"
#import <GooglePlaces/GooglePlaces.h>
#import <GooglePlacePicker/GooglePlacePicker.h>



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
    locationSelected = NO;
    // Do any additional setup after loading the view.
    
    self.lenientValidator = [NJOPasswordValidator standardValidator];
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification object:passwordTextField queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self updatePasswordStrength:note.object];
    }];
    
    [self updatePasswordStrength:self];

}

- (BOOL)checkFields{
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
    if (!locationSelected) {
        [self showAlertView:@"Please Select a Location First"];
        return false;
    }
    return true;
}


- (IBAction)signUpButtonTap:(UIButton *)sender {
    if ([self checkFields]){
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
        NSData *imageData = UIImagePNGRepresentation(selectedImage);
        PFFileObject *image = [PFFileObject fileObjectWithName:@"Profileimage.png" data:imageData];
        
        PFUser *user = [PFUser user];
        user.username = self->nameTextField.text;
        user.password = self->passwordTextField.text;
        user.email = self->emailTextField.text;
        user[@"ProfilePic"] = image;
        
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [hud hideAnimated:YES];
            if (!error) {
                [self showAlertView:@"Welcome!"];
                [self performSegueWithIdentifier:@"homeScreen" sender:nil];
            } else {
                [hud hideAnimated:YES];
                [self showAlertView:@"Someything goes wrong, Please try again"];
                NSLog(@"😫😫😫, error: %@", error.localizedDescription);
            }
        }];
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

- (IBAction)locationButtonTap:(UIButton *)sender {
    GMSPlacePickerConfig *config = [[GMSPlacePickerConfig alloc] initWithViewport:nil];
    GMSPlacePickerViewController *placePicker =
    [[GMSPlacePickerViewController alloc] initWithConfig:config];
    placePicker.delegate = self;
    
    [self presentViewController:placePicker animated:YES completion:nil];
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

- (void)placePicker:(GMSPlacePickerViewController *)viewcontroller didPickPlace:(GMSPlace *)place {
    
    // Dismiss the place picker, as it cannot dismiss itself.
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"Place name is %@", place.name);
    NSLog(@"Place address is %@", place.formattedAddress);
    NSLog(@"Place attribute is %@", place.attributions.string);

    [addLocationButton setTitle:place.formattedAddress forState:UIControlStateNormal];
    locationSelected = YES;
    selectedLocationPoint = [PFGeoPoint geoPointWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude];
}

- (void)placePickerDidCancel:(GMSPlacePickerViewController *)viewController {
    // Dismiss the place picker, as it cannot dismiss itself.
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"No place selected");
}


@end
