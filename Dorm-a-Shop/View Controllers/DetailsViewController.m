//
//  DetailsViewController.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "DetailsViewController.h"
#import "Post.h"
#import "PostManager.h"
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"ChangedWatchNotification"
                                               object:nil];
    
    [self setDetailsPost:self.post];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self isMovingFromParentViewController]) {
        [self.delegate updateDetailsData:self];
    }
}

- (void)receiveNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"ChangedWatchNotification"]) {
        if (self.post.watch != nil) {
            self.watchButton.selected = YES;
            [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%@ watching)", self.post.watchCount] forState:UIControlStateSelected];
        } else {
            self.watchButton.selected = NO;
            [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%@ watching)", self.post.watchCount] forState:UIControlStateNormal];
        }
    }
}

- (void)setDetailsPost:(Post *)post {
    _post = post;
    
    if ([((PFObject *)post[@"author"]).objectId isEqualToString:PFUser.currentUser.objectId] && post[@"sold"] == [NSNumber numberWithBool: NO]) {
        [self.statusButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [self.statusButton setTitle:@"active" forState:UIControlStateNormal];
        self.statusButton.hidden = NO;
    }
    
    if (post[@"sold"] == [NSNumber numberWithBool: YES]) {
        self.statusButton.hidden = NO;
    }
    
    self.postPFImageView.file = post[@"image"];
    [self.postPFImageView loadInBackground];
    
    if (self.post.watch != nil) {
        [self.watchButton setSelected:YES];
        [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%@ watching)", self.post.watchCount] forState:UIControlStateSelected];
    } else {
        [self.watchButton setSelected:NO];
        [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%@ watching)", self.post.watchCount] forState:UIControlStateNormal];
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
    if (self.post.watch != nil) {
        [[PostManager shared] unwatchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post,@"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:self userInfo:watchInfoDict];
            } else {
                NSLog(@"Delete watch object (user/post pair) in database failed: %@", error.localizedDescription);
            }
        }];
    } else {
        [[PostManager shared] watchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post,@"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:self userInfo:watchInfoDict];
            } else {
                NSLog(@"There was an error adding to watch class in database: %@", error.localizedDescription);
            }
        }];
    }
}

- (IBAction)changeStatus:(id)sender {
    if([((PFObject *) self.post[@"author"]).objectId isEqualToString:PFUser.currentUser.objectId]) {
        if (self.post.sold == NO) {
            [[PostManager shared] setPost:self.post sold:YES withCompletion:^(NSError * _Nonnull error) {
                if (error != nil) {
                    NSLog(@"Post sold status update failed: %@", error.localizedDescription);
                } else {
                    [self.statusButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                    [self.statusButton setTitle:@"sold" forState:UIControlStateNormal];
                    self.itemStatusChanged = YES;
                }
            }];
        } else {
            [[PostManager shared] setPost:self.post sold:NO withCompletion:^(NSError * _Nonnull error) {
                if (error != nil) {
                    NSLog(@"Post sold status update failed: %@", error.localizedDescription);
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
