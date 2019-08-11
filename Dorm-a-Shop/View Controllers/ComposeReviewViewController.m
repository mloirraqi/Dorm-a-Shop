//
//  ComposeReviewViewController.m
//  
//
//  Created by ilanashapiro on 8/1/19.
//

#import "ComposeReviewViewController.h"
#import "ReviewCoreData+CoreDataClass.h"
#import "CoreDataManager.h"
#import "ParseDatabaseManager.h"
#import "AppDelegate.h"
#import "Review.h"
#import "NSNotificationCenter+MainThread.h"

@interface ComposeReviewViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *chooseRatingButton;
@property (weak, nonatomic) IBOutlet UITextView *reviewTextView;
@property (weak, nonatomic) IBOutlet UITextView *itemDescriptionTextView;
@property (weak, nonatomic) IBOutlet UITextView *titleTextView;
@property (weak, nonatomic) IBOutlet UIPickerView *ratingPickerView;
@property (weak, nonatomic) IBOutlet UIToolbar *pickerViewToolbar;
@property (strong, nonatomic) UIAlertController *reviewEmptyAlert;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) AppDelegate *appDelegate;

- (IBAction)didTapCancel:(id)sender;
- (IBAction)didTapSubmit:(id)sender;

@end

@implementation ComposeReviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *textViews = @[self.reviewTextView, self.itemDescriptionTextView, self.titleTextView];
    
    for (UITextView *textView in textViews) {
        textView.layer.cornerRadius = 5;
        textView.layer.borderWidth = 1.0f;
        textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        textView.delegate = self;
    }
    
    self.chooseRatingButton.layer.cornerRadius = 5;
    self.chooseRatingButton.layer.borderWidth = 1.0f;
    self.chooseRatingButton.layer.borderColor = [UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:1].CGColor;
    self.chooseRatingButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    
    self.reviewTextView.text = @"Write review here";
    self.reviewTextView.textColor = [UIColor lightGrayColor];
    
    self.titleTextView.text = @"Give a short title for your review";
    self.titleTextView.textColor = [UIColor lightGrayColor];
    
    self.itemDescriptionTextView.text = @"Write a short description of the item you're reviewing";
    self.itemDescriptionTextView.textColor = [UIColor lightGrayColor];
    
    self.reviewEmptyAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Review empty" preferredStyle:(UIAlertControllerStyleAlert)];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [self.reviewEmptyAlert addAction:okAction];
    
    self.appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = self.appDelegate.persistentContainer.viewContext;
    
    self.ratingPickerView.delegate = self;
    self.ratingPickerView.dataSource = self;
    self.ratingPickerView.hidden = YES;
    self.pickerViewToolbar.hidden = YES;
}

- (IBAction)didTapCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)didTapSubmit:(id)sender {
    if ([self.reviewTextView.text isEqual:@""]) {
        [self presentViewController:self.reviewEmptyAlert animated:YES completion:^{
        }];
    } else {
        UserCoreData *sellerCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:self.seller.objectId withContext:self.context];
        UserCoreData *reviewerCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:PFUser.currentUser.objectId withContext:self.context];
        
        //set date and objectId later, in order to get them from parse
        ReviewCoreData *reviewCoreData = [[CoreDataManager shared] saveReviewToCoreDataWithObjectId:nil withSeller:sellerCoreData withReviewer:reviewerCoreData withRating:[self.chooseRatingButton.titleLabel.text intValue] withReview:self.reviewTextView.text withTitle:self.titleTextView.text withItemDescription:self.itemDescriptionTextView.text withDate:nil withManagedObjectContext:self.context];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
        NSNumber *ratingNumber = [formatter numberFromString:self.chooseRatingButton.titleLabel.text];
        User *pfSeller = (User *)[PFObject objectWithoutDataWithClassName:@"_User" objectId:self.seller.objectId];
        [[ParseDatabaseManager shared] postReviewToParseWithSeller:pfSeller withRating:ratingNumber withReview:self.reviewTextView.text withTitle:self.titleTextView.text withItemDescription:self.itemDescriptionTextView.text withCompletion:^(Review * _Nullable review, NSError * _Nullable error) {
            if (error) {
                NSLog(@"😫😫😫 Error uploading picture: %@", error.localizedDescription);
            } else {
                reviewCoreData.objectId = review.objectId;
                reviewCoreData.dateWritten = review.createdAt;
                
                [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
                    return YES;
                } withName:reviewCoreData.objectId];
                [self saveContext];
                
                [self dismissViewControllerAnimated:true completion:nil];
            }
        }];
        
        NSDictionary *reviewInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:reviewCoreData, @"review", nil];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DidReviewNotification" object:self userInfo:reviewInfoDict];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 5;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%ld", row + 1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self.chooseRatingButton setTitle:[NSString stringWithFormat:@"%ld", row + 1] forState:UIControlStateNormal];
}

- (IBAction)onTap:(id)sender {
    [self.reviewTextView endEditing:YES];
    [self.itemDescriptionTextView endEditing:YES];
    [self.titleTextView endEditing:YES];
    self.ratingPickerView.hidden = YES;
    self.pickerViewToolbar.hidden = YES;
}

- (IBAction)didPressRate:(id)sender {
    [self.reviewTextView endEditing:YES];
    self.ratingPickerView.hidden = NO;
    self.pickerViewToolbar.hidden = NO;
}

- (IBAction)didTapDone:(id)sender {
    [self.reviewTextView endEditing:YES];
    self.ratingPickerView.hidden = YES;
    self.pickerViewToolbar.hidden = YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.ratingPickerView.hidden = YES;
    self.pickerViewToolbar.hidden = YES;
    
    if ([textView isEqual:self.reviewTextView]) {
        [self.titleTextView endEditing:YES];
        [self.itemDescriptionTextView endEditing:YES];
        
        if ([self.reviewTextView.text isEqualToString:@"Write review here"]) {
            self.reviewTextView.text = @"";
            self.reviewTextView.textColor = [UIColor blackColor];
        }
        
        [self.reviewTextView becomeFirstResponder];
    } else if ([textView isEqual:self.itemDescriptionTextView]) {
        [self.titleTextView endEditing:YES];
        [self.reviewTextView endEditing:YES];
        
        if ([self.itemDescriptionTextView.text isEqualToString:@"Write a short description of the item you're reviewing"]) {
            self.itemDescriptionTextView.text = @"";
            self.itemDescriptionTextView.textColor = [UIColor blackColor];
        }
        
        [self.itemDescriptionTextView becomeFirstResponder];
    } else if ([textView isEqual:self.titleTextView]) {
        [self.reviewTextView endEditing:YES];
        [self.itemDescriptionTextView endEditing:YES];
        
        if ([self.titleTextView.text isEqualToString:@"Give a short title for your review"]) {
            self.titleTextView.text = @"";
            self.titleTextView.textColor = [UIColor blackColor];
        }
        
        [self.titleTextView becomeFirstResponder];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView isEqual:self.reviewTextView]) {
        if ([textView.text isEqualToString:@""]) {
            textView.text = @"Write review here";
            textView.textColor = [UIColor lightGrayColor];
        }
        [textView resignFirstResponder];
    } else if ([textView isEqual:self.itemDescriptionTextView]) {
        if ([textView.text isEqualToString:@""]) {
            textView.text = @"Write a short description of the item you're reviewing";
            textView.textColor = [UIColor lightGrayColor];
        }
        [textView resignFirstResponder];
    } else if ([textView isEqual:self.titleTextView]) {
        if ([textView.text isEqualToString:@""]) {
            textView.text = @"Give a short title for your review";
            textView.textColor = [UIColor lightGrayColor];
        }
        [textView resignFirstResponder];
    }
}

- (void)saveContext {
    NSError *error = nil;
    if ([self.context hasChanges] && ![self.context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
