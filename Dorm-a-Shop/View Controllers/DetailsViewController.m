//
//  DetailsViewController.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "DetailsViewController.h"
#import "Post.h"
@import Parse;

@interface DetailsViewController ()

- (IBAction)didTapWatch:(id)sender;

@property (weak, nonatomic) IBOutlet PFImageView *postPFImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UIButton *sellerButton;
@property (weak, nonatomic) IBOutlet UIButton *watchButton;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setPostDetailContents:self.post];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self isMovingFromParentViewController]) {
        //[self.delegate updateData:self];
    }
}

- (void)setPostDetailContents:(Post *)post {
    _post = post;
    
    self.postPFImageView.file = post[@"image"];
    [self.postPFImageView loadInBackground];
    
    /*self.watchButton.layer.borderWidth = 1.0f;
    self.watchButton.layer.borderColor = [UIColor blueColor].CGColor;
    self.watchButton.layer.cornerRadius = 4.0f;
    self.watchButton.backgroundColor = [UIColor whiteColor];
    self.watchButton.textcolor = [UIColor whiteColor];
    [self.watchButton setTitleColor:[UIColor colorWithRed:36/255.0 green:71/255.0 blue:113/255.0 alpha:1.0] forState:UIControlStateNormal];*/
    
    [self setWatched:[PFUser currentUser] forPost:post];
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}

- (void)setWatched:(PFUser *)user forPost:(Post *)post {
    if ([[PFUser currentUser] objectForKey:@"Watches"]) {
        PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
        [watchQuery orderByDescending:@"createdAt"];
        [watchQuery includeKey:@"user"];
        [watchQuery whereKey:@"userID" equalTo:[PFUser currentUser].objectId];
        [watchQuery whereKey:@"postID" equalTo:self.post.objectId];
        
        [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable watches, NSError * _Nullable error) {
            if (error) {
                NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
            }
            else if (watches) {
                self.watchButton.titleLabel.text = [NSString stringWithFormat:@"Watched (%@ watching)", post.watchCount];
            }
            else {
                self.watchButton.titleLabel.text = [NSString stringWithFormat:@"Watch (%@ watching)", post.watchCount];
            }
        }];
    }
}

- (IBAction)didTapWatch:(id)sender {
    NSLog(@"Tapped watch!");
    
    /*if ([[PFUser currentUser] objectForKey:@"Watches"] && [self.post objectForKey:@"Watches"]) {
        [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded && !error) {
                NSLog(@"Image deleted from Parse");
            } else {
                NSLog(@"error: %@", error);
            }
        }];
    }
    
    PFObject *watch = [PFObject objectWithClassName:@"Watches"];
    watch[@"postID"] = self.post.objectId;
    watch[@"userID"] = self.post.author.objectId;
    
    [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"Successfully added to watch class in databse");
        }
        else {
            NSLog(@"There was an error adding to watch class in database: %@", error.localizedDescription);
        }
    }];*/
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
