//
//  UploadViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "UploadViewController.h"
#import "Post.h"

@interface UploadViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *itemTitle;
@property (weak, nonatomic) IBOutlet UITextField *itemPrice;
@property (weak, nonatomic) IBOutlet UITextView *itemDescription;
@property (weak, nonatomic) IBOutlet UIButton *categoryShown;
@property (weak, nonatomic) IBOutlet UIButton *conditionShown;
@property (weak, nonatomic) IBOutlet UIPickerView *categoryPickerView;
@property (weak, nonatomic) IBOutlet UIPickerView *conditionPickerView;
@property (weak, nonatomic) IBOutlet UIButton *picButton;
@property (strong, nonatomic) NSArray *categories;
@property (strong, nonatomic) NSArray *conditions;
@property (strong, nonatomic) UIImage *postImage;
@property (weak, nonatomic) NSNumberFormatter *formatter;

@end

@implementation UploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.itemDescription.layer.borderWidth = 1.0f;
    self.itemDescription.layer.borderColor = [[UIColor grayColor] CGColor];
    
    self.categoryPickerView.delegate = self;
    self.categoryPickerView.dataSource = self;
    self.categoryPickerView.hidden = YES;
    
    self.conditionPickerView.delegate = self;
    self.conditionPickerView.dataSource = self;
    self.conditionPickerView.hidden = YES;
    
    self.categories = @[@"Furniture", @"Books", @"Beauty"];
    self.conditions = @[@"New", @"Nearly New", @"Old"];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.formatter = formatter;
}

- (IBAction)addPicture:(id)sender {
    UIImagePickerController *imagePickerVC = [UIImagePickerController new];
    imagePickerVC.delegate = self;
    imagePickerVC.allowsEditing = YES;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else {
        NSLog(@"Camera 🚫 available so we will use photo library instead");
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [self presentViewController:imagePickerVC animated:YES completion:nil];
}

// save the image pictured and upload button
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    self.postImage = info[UIImagePickerControllerEditedImage];
    [self.picButton setImage:self.postImage forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// save pics to database
- (IBAction)uploadPic:(id)sender {
    NSNumber *priceNum = [self.formatter numberFromString:self.itemPrice.text];
    Post *newPost = [Post postListing:self.postImage withCaption:self.itemDescription.text withPrice:priceNum withCondition:self.conditionShown.titleLabel.text withCategory:self.categoryShown.titleLabel.text withTitle:self.itemTitle.text withCompletion:^(BOOL succeeded, NSError * _Nullable error) {
            if (!succeeded) {
                NSLog(@"😫😫😫 Error uploading picture: %@", error.localizedDescription);
            } else {
                NSLog(@"😎😎😎 Successfully uploaded picture");
                [self dismissViewControllerAnimated:true completion:nil];
            }
    }];
    [self.delegate didUpload:newPost];
}

- (IBAction)cancelPost:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView { 
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView == self.categoryPickerView) {
        return self.categories.count;
    } else {
        return self.conditions.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView == self.categoryPickerView) {
        return self.categories[row];
    } else {
        return self.conditions[row];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == self.categoryPickerView) {
        [self.categoryShown setTitle:self.categories[row] forState:UIControlStateNormal];
        self.categoryPickerView.hidden = YES;
    } else {
        [self.conditionShown setTitle:self.conditions[row] forState:UIControlStateNormal];
        self.conditionPickerView.hidden = YES;
    }
}

- (IBAction)changeCategory:(id)sender {
    self.conditionPickerView.hidden = YES;
    self.categoryPickerView.hidden = NO;
}

- (IBAction)changeCondition:(id)sender {
    self.categoryPickerView.hidden = YES;
    self.conditionPickerView.hidden = NO;
}

@end
