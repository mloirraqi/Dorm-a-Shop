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
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
#import "PostCollectionViewCell.h"
#import "NSNotificationCenter+MainThread.h"
#import "ProfileViewController.h"
#import "UILabel+Boldify.h"
#import <QuartzCore/QuartzCore.h>
#import "AKStencilButton.h"
@import Parse;

@interface DetailsViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate>

- (IBAction)didTapWatch:(id)sender;

@property (weak, nonatomic) IBOutlet UIImageView *postImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UIButton *sellerButton;
@property (weak, nonatomic) IBOutlet UIButton *watchButton;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (weak, nonatomic) IBOutlet UIButton *contactSellerButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *similarItems;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *sellerLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionCategoryWatchesLabel;
@property (weak, nonatomic) IBOutlet AKStencilButton *ARButton;


@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.statusButton.hidden = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.similarItems = [[CoreDataManager shared] getSimilarPostsFromCoreData:self.post];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
    layout.minimumInteritemSpacing = 3;
    
    [[ParseDatabaseManager shared] viewPost:self.post];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedWatchNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedSoldNotification" object:nil];
    
    [self setDetailsPost:self.post];
}

- (void)receiveNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"ChangedWatchNotification"]) {
        [self.watchButton setSelected:self.post.watched];
        if (self.post.watched) {
            [self.watchButton setTitle:@"Unwatch" forState:UIControlStateSelected];
            
            [self.watchButton setTitleColor:[UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:0.8] forState:UIControlStateSelected];
            self.watchButton.titleLabel.backgroundColor = [UIColor whiteColor];
            self.watchButton.titleLabel.tintColor = [UIColor clearColor];
            self.watchButton.backgroundColor = [UIColor whiteColor];
            self.watchButton.tintColor = [UIColor clearColor];
            self.watchButton.layer.borderWidth = 1.0f;
            self.watchButton.layer.borderColor = [UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:1].CGColor;
            self.watchButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        } else {
            [self.watchButton setTitle:@"Watch" forState:UIControlStateNormal];
            
            [self.watchButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            self.watchButton.titleLabel.backgroundColor = [UIColor whiteColor];
            self.watchButton.titleLabel.tintColor = [UIColor clearColor];
            self.watchButton.backgroundColor = [UIColor whiteColor];
            self.watchButton.tintColor = [UIColor clearColor];
            self.watchButton.layer.borderWidth = 1.0f;
            self.watchButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
            self.watchButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        }
    } else if ([[notification name] isEqualToString:@"ChangedSoldNotification"]) {
        NSNumber *soldNumVal = [[notification userInfo] objectForKey:@"sold"];
        BOOL sold = [soldNumVal boolValue];
       
        if (sold) {
            [self.statusButton setTitleColor:[UIColor colorWithRed:214/255.0 green:17/255.0 blue:17/255.0 alpha:0.85] forState:UIControlStateNormal];
            [self.statusButton setTitle:@"sold" forState:UIControlStateNormal];
        } else {
            [self.statusButton setTitleColor:[UIColor colorWithRed:49/255.0 green:179/255.0 blue:25/255.0 alpha:0.85] forState:UIControlStateNormal];
            [self.statusButton setTitle:@"active" forState:UIControlStateNormal];
        }
    }
}

- (void)setDetailsPost:(PostCoreData *)post {
    _post = post;
    
    if ([post.author.objectId isEqualToString:PFUser.currentUser.objectId] && post.sold == NO) {
        [self.statusButton setTitleColor:[UIColor colorWithRed:40/255.0 green:156/255.0 blue:19/255.0 alpha:0.85] forState:UIControlStateNormal];
        [self.statusButton setTitle:@"active" forState:UIControlStateNormal];
        self.statusButton.hidden = NO;
    }
    
    if (post.sold == YES) {
        [self.statusButton setTitleColor:[UIColor colorWithRed:214/255.0 green:17/255.0 blue:17/255.0 alpha:0.85] forState:UIControlStateNormal];
        self.statusButton.hidden = NO;
    }
    
    [self.postImageView setImage:[UIImage imageNamed:@"item_placeholder"]];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapProfileImage:)];
    [self.postImageView addGestureRecognizer:tapGestureRecognizer];
    tapGestureRecognizer.delegate = self;
    if (self.post.image) {
        [self.postImageView setImage:[UIImage imageWithData:self.post.image]];
    }
    
    self.watchButton.layer.cornerRadius = 5;
    [self.watchButton setSelected:self.post.watched];
    if (self.post.watched) {
        [self.watchButton setTitle:@"Unwatch" forState:UIControlStateSelected];
        
        [self.watchButton setTitleColor:[UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:0.8] forState:UIControlStateSelected];
        self.watchButton.titleLabel.backgroundColor = [UIColor whiteColor];
        self.watchButton.titleLabel.tintColor = [UIColor clearColor];
        self.watchButton.backgroundColor = [UIColor whiteColor];
        self.watchButton.tintColor = [UIColor clearColor];
        self.watchButton.layer.borderWidth = 1.0f;
        self.watchButton.layer.borderColor = [UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:1].CGColor;
        self.watchButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    } else {
        [self.watchButton setTitle:@"Watch" forState:UIControlStateNormal];
        
        [self.watchButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        self.watchButton.titleLabel.backgroundColor = [UIColor whiteColor];
        self.watchButton.titleLabel.tintColor = [UIColor clearColor];
        self.watchButton.backgroundColor = [UIColor whiteColor];
        self.watchButton.tintColor = [UIColor clearColor];
        self.watchButton.layer.borderWidth = 1.0f;
        self.watchButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.watchButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    }
    
    self.profileImageView.layer.cornerRadius = 15;
    self.profileImageView.layer.masksToBounds = YES;
    [self.profileImageView setImage:[UIImage imageWithData:self.post.author.profilePic]];
    
    self.conditionCategoryWatchesLabel.text = [NSString stringWithFormat:@"%@ · %@ · %lld Watching", post.condition, post.category, post.watchCount];
    
    self.captionLabel.text = [NSString stringWithFormat:@"Description: %@", post.caption];
    [self.captionLabel greySubstring:@"Description:"];
    
    self.titleLabel.text = post.title;
    self.sellerLabel.text = post.author.username;
    self.priceLabel.text = [NSString stringWithFormat:@"$%.02f", post.price];
    
    self.contactSellerButton.layer.cornerRadius = 5;
    [self.contactSellerButton setTitleColor:[UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:0.8] forState:UIControlStateNormal];
    self.contactSellerButton.titleLabel.backgroundColor = [UIColor whiteColor];
    self.contactSellerButton.titleLabel.tintColor = [UIColor clearColor];
    self.contactSellerButton.backgroundColor = [UIColor whiteColor];
    self.contactSellerButton.tintColor = [UIColor clearColor];
    self.contactSellerButton.layer.borderWidth = 1.0f;
    self.contactSellerButton.layer.borderColor = [UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:0.8].CGColor;
    self.contactSellerButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
}

- (IBAction)didTapWatch:(id)sender {
    __weak DetailsViewController *weakSelf = self;
    if (self.post.watched) {
        [[ParseDatabaseManager shared] unwatchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post,@"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            } else {
                NSLog(@"Delete watch object (user/post pair) in database failed: %@", error.localizedDescription);
            }
        }];
    } else {
        [[ParseDatabaseManager shared] watchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post,@"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
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
            [[ParseDatabaseManager shared] setPost:self.post sold:YES withCompletion:^(NSError * _Nonnull error) {
                if (error != nil) {
                    NSLog(@"Post sold status update failed: %@", error.localizedDescription);
                } else {
                    NSDictionary *soldInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"sold", weakSelf.post, @"post", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"ChangedSoldNotification" object:weakSelf userInfo:soldInfoDict];
                }
            }];
        } else {
            [[ParseDatabaseManager shared] setPost:self.post sold:NO withCompletion:^(NSError * _Nonnull error) {
                if (error != nil) {
                    NSLog(@"Post sold status update failed: %@", error.localizedDescription);
                } else {
                    NSDictionary *soldInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"sold", weakSelf.post, @"post", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"ChangedSoldNotification" object:weakSelf userInfo:soldInfoDict];
                }
            }];
        }
    }
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.similarItems.count;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"similarItems" forIndexPath:indexPath];
    PostCoreData *post = self.similarItems[indexPath.item];
    cell.post = post;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    DetailsViewController *newDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailsViewController"];
    newDetailVC.post = self.similarItems[indexPath.row];
    [self.navigationController pushViewController:newDetailVC animated:YES];
}

- (void)onTapProfileImage:(UITapGestureRecognizer *)recognizer {
    [self performSegueWithIdentifier:@"segueToAR" sender:nil];
}

- (IBAction)onTapARButton:(id)sender {
    [self performSegueWithIdentifier:@"segueToAR" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"contactSeller"]) {
        ProfileViewController *profileViewController = [segue destinationViewController];
        profileViewController.user = self.post.author;
    }
}

@end
