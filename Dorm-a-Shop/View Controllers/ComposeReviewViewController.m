//
//  ComposeReviewViewController.m
//  
//
//  Created by ilanashapiro on 8/1/19.
//

#import "ComposeReviewViewController.h"
#import "CoreDataManager.h"
#import "ParseManager.h"
#import "AppDelegate.h"
#import "Review.h"

@interface ComposeReviewViewController ()

@property (weak, nonatomic) IBOutlet UITextField *ratingTextField;
@property (weak, nonatomic) IBOutlet UITextView *reviewTextView;
@property (strong, nonatomic) UIAlertController *ratingEmptyAlert;
@property (strong, nonatomic) UIAlertController *reviewEmptyAlert;
@property (strong, nonatomic) NSManagedObjectContext *context;

- (IBAction)cancelAction:(id)sender;
- (IBAction)submitAction:(id)sender;

@end

@implementation ComposeReviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.ratingEmptyAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Rating empty" preferredStyle:(UIAlertControllerStyleAlert)];
    self.reviewEmptyAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Review empty" preferredStyle:(UIAlertControllerStyleAlert)];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [self.ratingEmptyAlert addAction:okAction];
    [self.reviewEmptyAlert addAction:okAction];
    
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
}

- (IBAction)cancelAction:(id)sender {
}

- (IBAction)submitAction:(id)sender {
    if ([self.ratingTextField.text isEqual:@""]) {
        [self presentViewController:self.ratingEmptyAlert animated:YES completion:^{
        }];
    } else if ([self.reviewTextView.text isEqual:@""]) {
        [self presentViewController:self.reviewEmptyAlert animated:YES completion:^{
        }];
    } else {
        UserCoreData *sellerCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:self.seller.objectId withContext:self.context];
        
        ReviewCoreData *reviewCoreData = [[CoreDataManager shared] saveReviewToCoreDataWithObjectId:nil withSeller:sellerCoreData withRating:[self.ratingTextField.text intValue] withReview:self.reviewTextView.text withManagedObjectContext:self.context];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
        NSNumber *ratingNumber = [formatter numberFromString:self.ratingTextField.text];
        User *pfSeller = (User *)[PFObject objectWithoutDataWithClassName:@"_User" objectId:self.seller.objectId];
        [[ParseManager shared] postReviewToParseWithSeller:pfSeller withRating:ratingNumber withReview:self.reviewTextView.text withCompletion:^(Review * _Nullable review, NSError * _Nullable error) {
            if (error) {
                NSLog(@"😫😫😫 Error uploading picture: %@", error.localizedDescription);
            } else {
                reviewCoreData.objectId = review.objectId;
                [self.context save:nil];
                
                [self dismissViewControllerAnimated:true completion:nil];
            }
        }];
        
        NSDictionary *reviewInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:reviewCoreData, @"review", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReviewNotification" object:self userInfo:reviewInfoDict];
    }
}
@end
