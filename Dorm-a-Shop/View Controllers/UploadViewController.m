//
//  UploadViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "UploadViewController.h"
#import "PostManager.h"
#import "Post.h"

@interface UploadViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *itemTitle;
@property (weak, nonatomic) IBOutlet UITextField *itemPrice;
@property (weak, nonatomic) IBOutlet UITextView *itemDescription;
@property (weak, nonatomic) IBOutlet UIButton *categoryShown;
@property (weak, nonatomic) IBOutlet UIButton *conditionShown;
@property (weak, nonatomic) IBOutlet UIPickerView *categoryPickerView;
@property (weak, nonatomic) IBOutlet UIToolbar *pickerviewToolbar;
@property (weak, nonatomic) IBOutlet UIPickerView *conditionPickerView;
@property (weak, nonatomic) IBOutlet UIButton *picButton;
@property (strong, nonatomic) NSArray *categories;
@property (strong, nonatomic) NSArray *conditions;
@property (strong, nonatomic) UIImage *postImage;
@property (weak, nonatomic) NSNumberFormatter *formatter;

@property (strong, nonatomic) UIAlertController *titleEmpty;
@property (strong, nonatomic) UIAlertController *priceEmpty;
@property (strong, nonatomic) UIAlertController *descriptionEmpty;

@end

@implementation UploadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.itemDescription.layer.borderWidth = 1.0f;
    self.itemDescription.layer.borderColor = [[UIColor blueColor] CGColor];
    self.itemDescription.delegate = self;
    self.itemDescription.text = @"add a description for the item here";
    self.itemDescription.textColor = [UIColor lightGrayColor];
    
    self.pickerviewToolbar.hidden = YES;
    self.categoryPickerView.delegate = self;
    self.categoryPickerView.dataSource = self;
    self.categoryPickerView.hidden = YES;
    self.conditionPickerView.delegate = self;
    self.conditionPickerView.dataSource = self;
    self.conditionPickerView.hidden = YES;
    
    self.categories = @[@"Other", @"Furniture", @"Books", @"Beauty"];
    self.conditions = @[@"New", @"Nearly New", @"Old"];
    
    [self.itemTitle addTarget:self.itemTitle action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    self.titleEmpty = [UIAlertController alertControllerWithTitle:@"Error" message:@"Item title empty" preferredStyle:(UIAlertControllerStyleAlert)];
    self.priceEmpty = [UIAlertController alertControllerWithTitle:@"Error" message:@"Item price empty" preferredStyle:(UIAlertControllerStyleAlert)];
    self.descriptionEmpty = [UIAlertController alertControllerWithTitle:@"Error" message:@"Item description empty" preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [self.titleEmpty addAction:okAction];
    [self.priceEmpty addAction:okAction];
    [self.descriptionEmpty addAction:okAction];
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    self.postImage = info[UIImagePickerControllerEditedImage];
    [self.picButton setImage:self.postImage forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)uploadPost:(id)sender {
    if ([self.itemTitle.text isEqual:@""]) {
        [self presentViewController:self.titleEmpty animated:YES completion:^{
        }];
    } else if ([self.itemPrice.text isEqual:@""]) {
        [self presentViewController:self.priceEmpty animated:YES completion:^{
        }];
    } else if ([self.itemDescription.text isEqual:@""] || [self.itemDescription.text isEqual:@"add a description for the item here"]) {
        [self presentViewController:self.descriptionEmpty animated:YES completion:^{
        }];
    } else {
        [[PostManager shared] postListing:self.postImage withCaption:self.itemDescription.text withPrice:self.itemPrice.text withCondition:self.conditionShown.titleLabel.text withCategory:self.categoryShown.titleLabel.text withTitle:self.itemTitle.text withCompletion:^(Post *newPost, NSError * _Nullable error) {
            if (error) {
                NSLog(@"😫😫😫 Error uploading picture: %@", error.localizedDescription);
            } else {
                [self dismissViewControllerAnimated:true completion:nil];
                [self.delegate didUpload:newPost];
            }
        }];
    }
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
    } else {
        [self.conditionShown setTitle:self.conditions[row] forState:UIControlStateNormal];
    }
}

- (IBAction)changeCategory:(id)sender {
    self.conditionPickerView.hidden = YES;
    self.categoryPickerView.hidden = NO;
    self.pickerviewToolbar.hidden = NO;
}

- (IBAction)changeCondition:(id)sender {
    self.categoryPickerView.hidden = YES;
    self.conditionPickerView.hidden = NO;
    self.pickerviewToolbar.hidden = NO;
}

- (IBAction)onTap:(id)sender {
    [self.itemPrice endEditing:YES];
    [self.itemDescription endEditing:YES];
    self.conditionPickerView.hidden = YES;
    self.categoryPickerView.hidden = YES;
    self.pickerviewToolbar.hidden = YES;
}

- (IBAction)donePicking:(id)sender {
    self.conditionPickerView.hidden = YES;
    self.categoryPickerView.hidden = YES;
    self.pickerviewToolbar.hidden = YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"add a description for the item here"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"add a description for the item here";
        textView.textColor = [UIColor lightGrayColor];
    }
    [textView resignFirstResponder];
}

@end
