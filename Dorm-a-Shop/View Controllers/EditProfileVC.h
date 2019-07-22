//
//  EditProfileVC.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

NS_ASSUME_NONNULL_BEGIN

@interface EditProfileVC : UIViewController <UINavigationControllerDelegate,UIImagePickerControllerDelegate, UITextFieldDelegate>

{
    __weak IBOutlet UITextField *emailTextField;
    __weak IBOutlet UITextField *nameTextField;
    __weak IBOutlet UITextField *passwordTextField;
    __weak IBOutlet UITextField *confirmPasswordTextField;
    __weak IBOutlet UIButton *addPictureButton;
    __weak IBOutlet UIButton *updateLocationButton;
    __weak IBOutlet UIButton *changePasswordStartButton;
    
    
    UIImage * selectedImage;
    BOOL locationSelected;
    PFGeoPoint *selectedLocationPoint;
}

@end

NS_ASSUME_NONNULL_END
