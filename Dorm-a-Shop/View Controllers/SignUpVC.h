//
//  SignUpVC.h
//  DormAShop
//
//  Created by mloirraqi on 7/12/19.
//  Copyright © 2019 mloirraqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Parse/Parse.h"
#import "LocationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface SignUpVC : UIViewController<UINavigationControllerDelegate,UIImagePickerControllerDelegate, UITextFieldDelegate>
{
    __weak IBOutlet UITextField *emailTextField;
    __weak IBOutlet UITextField *passwordTextField;
    __weak IBOutlet UITextField *nameTextField;
    __weak IBOutlet UIButton *addPictureButton;
    
    PFGeoPoint *selectedLocationPoint;
    UIImage * selectedImage;
    LocationManager *locationManager;
    
}
@property (nonatomic) IBOutlet UIProgressView *passwordStrengthMeterView;

- (IBAction)signUpButtonTap:(UIButton *)sender;
- (IBAction)backButtonTap:(UIButton *)sender;
- (IBAction)pictureButtonTap:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
