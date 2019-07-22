//
//  ProfileViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "ProfileViewController.h"
#import "PostCollectionViewCell.h"
#import "DetailsViewController.h"
#import "Post.h"
#import "SignInVC.h"
#import "PostManager.h"
@import Parse;

@interface ProfileViewController () <DetailsViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *activeItems;
@property (nonatomic, strong) NSMutableArray *soldItems;
@property (nonatomic, strong) NSNumber *selectedSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *activeCount;
@property (weak, nonatomic) IBOutlet UILabel *soldCount;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSString *className;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.className = @"ProfileViewController";
    
    if (!self.user) {
        self.user = PFUser.currentUser;
    } else {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        self.navigationItem.leftItemsSupplementBackButton = true;
    }
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.selectedSegment = 0;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    CGFloat posterPerLine = 2;
    CGFloat itemWidth = (self.collectionView.frame.size.width - layout.minimumInteritemSpacing * (posterPerLine - 1)) / posterPerLine;
    CGFloat itemHeight = itemWidth;
    layout.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchProfile) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.refreshControl];

    [self fetchProfile];
}

- (void)fetchProfile {
    self.username.text = self.user.username;
    self.navigationItem.title = [@"@" stringByAppendingString:self.user.username];
    self.profilePic.layer.cornerRadius = 40;
    self.profilePic.layer.masksToBounds = YES;
    PFFileObject *imageFile = self.user[@"ProfilePic"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:imageData];
            [self.profilePic setImage:image];
        }
    }];
    
//    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
//    [query includeKey:@"author"];
//    [query whereKey:@"author" equalTo:self.user];
//    [query orderByDescending:@"updatedAt"];
//
//    __weak ProfileViewController *weakSelf = self;
//    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
//        if (posts != nil) {
//            NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: NO]];
//            weakSelf.activeItems = [NSMutableArray arrayWithArray:[posts filteredArrayUsingPredicate:aPredicate]];
//            weakSelf.activeCount.text = [NSString stringWithFormat:@"%lu", weakSelf.activeItems.count];
//            NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: YES]];
//            weakSelf.soldItems = [NSMutableArray arrayWithArray:[posts filteredArrayUsingPredicate:sPredicate]];
//            weakSelf.soldCount.text = [NSString stringWithFormat:@"%lu", weakSelf.soldItems.count];
//            [weakSelf.collectionView reloadData];
//        } else {
//            NSLog(@"😫😫😫 couldn't fetch user's posts for some reason: %@", error.localizedDescription);
//        }
//    }];
    
    
    /*NSMutableArray *posts = [[PostManager shared] getProfilePosts:self.user];
    NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: NO]];
    self.activeItems = [NSMutableArray arrayWithArray:[posts filteredArrayUsingPredicate:aPredicate]];
    self.activeCount.text = [NSString stringWithFormat:@"%lu", self.activeItems.count];
    NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: YES]];
    self.soldItems = [NSMutableArray arrayWithArray:[posts filteredArrayUsingPredicate:sPredicate]];
    self.soldCount.text = [NSString stringWithFormat:@"%lu", self.soldItems.count];
    [self.collectionView reloadData];
    
    [self.refreshControl endRefreshing];*/

    [[PostManager shared] getAllPostsWithCompletion:^(NSMutableArray * _Nonnull postsArray, NSError * _Nonnull error) {
        if (postsArray) {
            NSLog(@"posts array 0: %@", postsArray[0]);
            NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(Post *post, NSDictionary *bindings) {
                return [((PFObject *)post[@"author"]).objectId isEqualToString:[PFUser currentUser].objectId];
            }];
            NSArray *profilePostsArray = [postsArray filteredArrayUsingPredicate:predicate];
            
            NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: NO]];
            self.activeItems = [NSMutableArray arrayWithArray:[profilePostsArray filteredArrayUsingPredicate:aPredicate]];
            self.activeCount.text = [NSString stringWithFormat:@"%lu", self.activeItems.count];
            NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: YES]];
            self.soldItems = [NSMutableArray arrayWithArray:[profilePostsArray filteredArrayUsingPredicate:sPredicate]];
            self.soldCount.text = [NSString stringWithFormat:@"%lu", self.soldItems.count];
            [self.collectionView reloadData];
        } else {
            NSLog(@"😫😫😫 Error getting home screen (all posts): %@", error.localizedDescription);
        }
        [self.refreshControl endRefreshing];
    }];
}

- (IBAction)changedSegment:(id)sender {
    [self.collectionView reloadData];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if ([self.segmentControl selectedSegmentIndex] == 0) {
        PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"active" forIndexPath:indexPath];
        Post *post = self.activeItems[indexPath.item];
        cell.post = post;
        [cell setPost];
        return cell;
    } else {
        PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sold" forIndexPath:indexPath];
        Post *post = self.soldItems[indexPath.item];
        cell.post = post;
        [cell setPost];
        return cell;
    }
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self.segmentControl selectedSegmentIndex] == 0) {
        return self.activeItems.count;
    } else {
        return self.soldItems.count;
    }
}

- (void)updateDetailsData:(UIViewController *)viewController {
    DetailsViewController *detailsViewController = (DetailsViewController *)viewController;
//    if (detailsViewController.watchStatusChanged) {
//        [self.collectionView reloadData];
//    } else
    if (detailsViewController.itemStatusChanged) {
        if (detailsViewController.post.sold == NO) {
            [self.activeItems insertObject:detailsViewController.post atIndex:0];
            [self.soldItems removeObject:detailsViewController.post];
        } else {
            [self.soldItems  insertObject:detailsViewController.post atIndex:0];
            [self.activeItems removeObject:detailsViewController.post];
        }
        [self.collectionView reloadData];
        self.activeCount.text = [NSString stringWithFormat:@"%lu", self.activeItems.count];
        self.soldCount.text = [NSString stringWithFormat:@"%lu", self.soldItems.count];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToDetails"]) {
        PostCollectionViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:tappedCell];
        Post *post;
        
        if ([self.segmentControl selectedSegmentIndex] == 0) {
            post = self.activeItems[indexPath.row];
        } else {
            post = self.soldItems[indexPath.row];
        }
        
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.delegate = self;
        detailsViewController.senderClassName = self.className;
        detailsViewController.post = post;
        NSLog(@"profile details post %@", detailsViewController.post);
    }
}

- (IBAction)logout:(id)sender {
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {}];
    
    SignInVC *signInVC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SignInVC"];
    
    [self presentViewController:signInVC animated:YES completion:nil];
}

@end
