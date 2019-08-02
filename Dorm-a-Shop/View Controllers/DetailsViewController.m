//
//  DetailsViewController.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "DetailsViewController.h"
#import "Post.h"
#import "PostCoreData+CoreDataClass.h"
#import "ParseManager.h"
@import Parse;

@interface DetailsViewController ()

- (IBAction)didTapWatch:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *postImageView;
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
    self.statusButton.hidden = YES;
    
    [[ParseManager shared] viewPost:self.post];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedWatchNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedSoldNotification" object:nil];
    
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
        [self.watchButton setSelected:self.post.watched];
        if (self.post.watched) {
            [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lld watching)", self.post.watchCount] forState:UIControlStateSelected];
        } else {
            [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lld watching)", self.post.watchCount] forState:UIControlStateNormal];
        }
    } else if ([[notification name] isEqualToString:@"ChangedSoldNotification"]) {
        NSNumber *soldNumVal = [[notification userInfo] objectForKey:@"sold"];
        BOOL sold = [soldNumVal boolValue];
       
        if (sold) {
            [self.statusButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [self.statusButton setTitle:@"sold" forState:UIControlStateNormal];
        } else {
            [self.statusButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
            [self.statusButton setTitle:@"active" forState:UIControlStateNormal];
        }
    }
}

- (void)setDetailsPost:(PostCoreData *)post {
    _post = post;
    
    if ([post.author.objectId isEqualToString:PFUser.currentUser.objectId] && post.sold == NO) {
        [self.statusButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [self.statusButton setTitle:@"active" forState:UIControlStateNormal];
        self.statusButton.hidden = NO;
    }
    
    if (post.sold == YES) {
        self.statusButton.hidden = NO;
    }
    
    [self.postImageView setImage:[UIImage imageNamed:@"item_placeholder"]];
    if (self.post.image) {
        [self.postImageView setImage:[UIImage imageWithData:self.post.image]];
    }
    
    [self.watchButton setSelected:self.post.watched];
    if (self.post.watched) {
        [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lld watching)", self.post.watchCount] forState:UIControlStateSelected];
    } else {
        [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lld watching)", self.post.watchCount] forState:UIControlStateNormal];
    }
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.captionLabel.text = post.caption;
    self.titleLabel.text = post.title;
    self.priceLabel.text = [NSString stringWithFormat:@"$%f", post.price];
}

- (IBAction)didTapWatch:(id)sender {
    __weak DetailsViewController *weakSelf = self;
    if (self.post.watched) {
        [[ParseManager shared] unwatchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post,@"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            } else {
                NSLog(@"Delete watch object (user/post pair) in database failed: %@", error.localizedDescription);
            }
        }];
    } else {
        [[ParseManager shared] watchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post,@"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            } else {
                NSLog(@"There was an error adding to watch class in database: %@", error.localizedDescription);
            }
        }];
    }
}

- (IBAction)changeStatus:(id)sender {
    __weak DetailsViewController *weakSelf = self;
    if ([self.post.author.objectId isEqualToString:PFUser.currentUser.objectId]) {
        if (weakSelf.post.sold == NO) {
            [[ParseManager shared] setPost:self.post sold:YES withCompletion:^(NSError * _Nonnull error) {
                if (error != nil) {
                    NSLog(@"Post sold status update failed: %@", error.localizedDescription);
                } else {
                    NSDictionary *soldInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"sold", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedSoldNotification" object:weakSelf userInfo:soldInfoDict];
                }
            }];
        } else {
            [[ParseManager shared] setPost:self.post sold:NO withCompletion:^(NSError * _Nonnull error) {
                if (error != nil) {
                    NSLog(@"Post sold status update failed: %@", error.localizedDescription);
                } else {
                    NSDictionary *soldInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"sold", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedSoldNotification" object:weakSelf userInfo:soldInfoDict];
                }
            }];
        }
    }
}



@end
