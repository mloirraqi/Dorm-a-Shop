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

@interface ComposeReviewViewController ()

@property (weak, nonatomic) IBOutlet UITextField *ratingTextField;
@property (weak, nonatomic) IBOutlet UITextView *reviewTextView;
@property (strong, nonatomic) UIAlertController *ratingEmptyAlert;
@property (strong, nonatomic) UIAlertController *reviewEmptyAlert;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) AppDelegate *appDelegate;

- (IBAction)didTapCancel:(id)sender;
- (IBAction)didTapSubmit:(id)sender;

@end

@implementation ComposeReviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ratingEmptyAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Rating empty" preferredStyle:(UIAlertControllerStyleAlert)];
    self.reviewEmptyAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Review empty" preferredStyle:(UIAlertControllerStyleAlert)];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [self.ratingEmptyAlert addAction:okAction];
    [self.reviewEmptyAlert addAction:okAction];
    
    self.appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = self.appDelegate.persistentContainer.viewContext;
}

- (IBAction)didTapCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)didTapSubmit:(id)sender {
    if ([self.ratingTextField.text isEqual:@""]) {
        [self presentViewController:self.ratingEmptyAlert animated:YES completion:^{
        }];
    } else if ([self.reviewTextView.text isEqual:@""]) {
        [self presentViewController:self.reviewEmptyAlert animated:YES completion:^{
        }];
    } else {
        UserCoreData *sellerCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:self.seller.objectId withContext:self.context];
        UserCoreData *reviewerCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:PFUser.currentUser.objectId withContext:self.context];
        
        //set date and objectId later, in order to get them from parse
        ReviewCoreData *reviewCoreData = [[CoreDataManager shared] saveReviewToCoreDataWithObjectId:nil withSeller:sellerCoreData withReviewer:reviewerCoreData withRating:[self.ratingTextField.text intValue] withReview:self.reviewTextView.text withDate:nil withManagedObjectContext:self.context];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
        NSNumber *ratingNumber = [formatter numberFromString:self.ratingTextField.text];
        User *pfSeller = (User *)[PFObject objectWithoutDataWithClassName:@"_User" objectId:self.seller.objectId];
        [[ParseDatabaseManager shared] postReviewToParseWithSeller:pfSeller withRating:ratingNumber withReview:self.reviewTextView.text withCompletion:^(Review * _Nullable review, NSError * _Nullable error) {
            if (error) {
                NSLog(@"😫😫😫 Error uploading picture: %@", error.localizedDescription);
            } else {
                reviewCoreData.objectId = review.objectId;
                reviewCoreData.dateWritten = review.createdAt;
                
                [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
                    return YES;
                } withName:[NSString stringWithFormat:@"%@", reviewCoreData.objectId]];
                
                [self dismissViewControllerAnimated:true completion:nil];
            }
        }];
        
        NSDictionary *reviewInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:reviewCoreData, @"review", nil];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DidReviewNotification" object:self userInfo:reviewInfoDict];
    }
}
@end
