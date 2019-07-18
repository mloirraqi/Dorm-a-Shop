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
@property (weak, nonatomic) IBOutlet UIButton *statusButton;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.watchStatusChanged = NO;
    self.itemStatusChanged = NO;
    self.statusButton.hidden = YES;
    [self setDetailsPost:self.post];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self isMovingFromParentViewController]) {
        [self.delegate updateDetailsData:self];
    }
}

- (void)setDetailsPost:(Post *)post {
    _post = post;
    
    if([((PFObject *) post[@"author"]).objectId isEqualToString:PFUser.currentUser.objectId] && post[@"sold"] == [NSNumber numberWithBool: NO]) {
        [self.statusButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [self.statusButton setTitle:@"active" forState:UIControlStateNormal];
        self.statusButton.hidden = NO;
    }
    
    if(post[@"sold"] == [NSNumber numberWithBool: YES]) {
        self.statusButton.hidden = NO;
    }
    
    self.postPFImageView.file = post[@"image"];
    [self.postPFImageView loadInBackground];
    
    if (self.watch != nil) {
        [self.watchButton setSelected:YES];
        [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", self.watchCount] forState:UIControlStateNormal];
    }
    else {
        [self.watchButton setSelected:NO];
        [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", self.watchCount] forState:UIControlStateNormal];
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
                
                //                int watchCountInt = [weakSelf.post.watchCount intValue];
                //                watchCountInt --;
                //                weakSelf.post.watchCount = [NSNumber numberWithInt:watchCountInt];
                weakSelf.watchCount --;
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", weakSelf.watchCount] forState:UIControlStateNormal];
                
                /*[weakSelf.post setObject:self.post.watchCount forKey:@"watchCount"];
                 [weakSelf.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                 if (error != nil) {
                 NSLog(@"Post watchCount update failed: %@", error.localizedDescription);
                 }
                 }];*/
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
                
                //                int watchCountInt = [weakSelf.post.watchCount intValue];
                //                watchCountInt ++;
                //                weakSelf.post.watchCount = [NSNumber numberWithInt:watchCountInt];
                weakSelf.watchCount ++;
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", weakSelf.watchCount] forState:UIControlStateNormal];
                
                //                [weakSelf.post setObject:weakSelf.post.watchCount forKey:@"watchCount"];
                //                [weakSelf.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                //                    if (error != nil) {
                //                        NSLog(@"Post watchCount update failed: %@", error.localizedDescription);
                //                    }
                //                }];
            } else {
                NSLog(@"There was an error adding to watch class in database: %@", error.localizedDescription);
            }
        }];
    }
}

- (IBAction)changeStatus:(id)sender {
    if([((PFObject *) self.post[@"author"]).objectId isEqualToString:PFUser.currentUser.objectId]) {
        if (self.post.sold == NO) {
            self.post.sold = YES;
            [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error != nil) {
                    NSLog(@"Post status update failed: %@", error.localizedDescription);
                } else {
                    [self.statusButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                    [self.statusButton setTitle:@"sold" forState:UIControlStateNormal];
                    self.itemStatusChanged = YES;
                }
            }];
        } else {
            self.post.sold = NO;
            [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error != nil) {
                    NSLog(@"Post status update failed: %@", error.localizedDescription);
                } else {
                    [self.statusButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
                    [self.statusButton setTitle:@"active" forState:UIControlStateNormal];
                    self.itemStatusChanged = YES;
                }
            }];
        }
    }
}


@end
