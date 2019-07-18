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

- (void)viewWillAppear:(BOOL)animated {
    self.watchStatusChanged = NO;
    [self setPostDetailContents:self.post];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self isMovingFromParentViewController]) {
        [self.delegate updateDetailsData:self];
    }
}

- (void)setPostDetailContents:(Post *)post {
    _post = post;
    
    self.postPFImageView.file = post[@"image"];
    [self.postPFImageView loadInBackground];
    
    if (self.watch != nil) {
        [self.watchButton setSelected:YES];
        [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%@ watching)", post.watchCount] forState:UIControlStateNormal];
    }
    else {
        [self.watchButton setSelected:NO];
        [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%@ watching)", post.watchCount] forState:UIControlStateNormal];
    }
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.captionLabel.text = post.caption;
    self.titleLabel.text = post.title;
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}

- (IBAction)didTapWatch:(id)sender {
    self.watchStatusChanged = YES;
    
    __weak DetailsViewController *weakSelf = self;
    if (self.watchButton.selected) {
        [self.watch deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                weakSelf.watch = nil;
                weakSelf.watchButton.selected = NO;
                
                int watchCountInt = [weakSelf.post.watchCount intValue];
                watchCountInt --;
                weakSelf.post.watchCount = [NSNumber numberWithInt:watchCountInt];
                
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%@ watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
                [weakSelf.watchButton setSelected:NO];
                
                [weakSelf.post setObject:weakSelf.post.watchCount forKey:@"watchCount"];
                [weakSelf.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error != nil) {
                        NSLog(@"Post watchCount update failed: %@", error.localizedDescription);
                    }
                }];
            } else {
                NSLog(@"Delete watch object (user/post pair) in database failed: %@", error.localizedDescription);
            }
        }];
    } else {
        PFObject *watch = [PFObject objectWithClassName:@"Watches"];
        watch[@"postID"] = self.post.objectId;
        watch[@"userID"] = [PFUser currentUser].objectId;
        
        [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                weakSelf.watch = watch;
                weakSelf.watchButton.selected = YES;
                
                int watchCountInt = [weakSelf.post.watchCount intValue];
                watchCountInt ++;
                weakSelf.post.watchCount = [NSNumber numberWithInt:watchCountInt];
                
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%@ watching)", weakSelf.post.watchCount] forState:UIControlStateSelected];
                [weakSelf.watchButton setSelected:YES];
                
                [weakSelf.post setObject:weakSelf.post.watchCount forKey:@"watchCount"];
                [weakSelf.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error != nil) {
                        NSLog(@"Post watchCount update failed: %@", error.localizedDescription);
                    }
                }];
            } else {
                NSLog(@"There was an error adding to watch class in database: %@", error.localizedDescription);
            }
        }];
    }
}

@end
