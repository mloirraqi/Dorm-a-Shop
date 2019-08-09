//
//  EditProfileVC.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "UserCoreData+CoreDataClass.h"
NS_ASSUME_NONNULL_BEGIN

@protocol EditProfileViewControllerDelegate <NSObject>

- (void)updateEditProfileData:(UIViewController *)editProfileViewController;

@end

@interface EditProfileVC : UIViewController <UINavigationControllerDelegate,UIImagePickerControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UserCoreData *user;
@property (nonatomic, strong) id<EditProfileViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic) BOOL locationSelected;
@property (nonatomic, strong) PFGeoPoint *selectedLocationPoint;

@end

NS_ASSUME_NONNULL_END
