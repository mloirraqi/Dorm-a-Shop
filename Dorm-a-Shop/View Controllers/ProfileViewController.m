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
#import "EditProfileVC.h"
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "MessageViewController.h"
#import "ComposeReviewViewController.h"
#import "SellerReviewsViewController.h"
#import "UILabel+Boldify.h"
#import "UserCollectionCell.h"
@import Parse;

@interface ProfileViewController () <EditProfileViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    CGSize itemSize;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *activeItems;
@property (nonatomic, strong) NSMutableArray *soldItems;
@property (nonatomic, strong) NSNumber *selectedSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *activeCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *soldCountLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (weak, nonatomic) IBOutlet UIButton *messageBtn;
@property (weak, nonatomic) IBOutlet UIButton *viewReviewBtn;
@property (weak, nonatomic) IBOutlet UIButton *writeReviewBtn;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.user) {
        self.appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        self.context = self.appDelegate.persistentContainer.viewContext;
        self.user = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:PFUser.currentUser.objectId withContext:self.context];
    } else {
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        self.navigationItem.leftItemsSupplementBackButton = true;
    }
    
    self.messageBtn.layer.cornerRadius = 10;
    self.messageBtn.layer.masksToBounds = YES;
    self.viewReviewBtn.layer.cornerRadius = 10;
    self.viewReviewBtn.layer.masksToBounds = YES;
    self.writeReviewBtn.layer.cornerRadius = 10;
    self.writeReviewBtn.layer.masksToBounds = YES;
    
    self.messageBtn.layer.borderWidth = 1.0f;
    self.messageBtn.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    [self.messageBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.viewReviewBtn.layer.borderWidth = 1.0f;
    self.viewReviewBtn.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    [self.viewReviewBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.writeReviewBtn.layer.borderWidth = 1.0f;
    self.writeReviewBtn.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    [self.writeReviewBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.selectedSegment = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DidUploadNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedSoldNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DoneSavingPostsWatches" object:nil];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchProfileFromCoreData) forControlEvents:UIControlEventValueChanged];
    [self.scrollView addSubview:self.refreshControl];
    
    [self fetchProfileFromCoreData];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"DidUploadNotification"]) {
        PostCoreData *notificationPost = [[notification userInfo] objectForKey:@"post"];
        [self.activeItems insertObject:notificationPost atIndex:0];
        [self.collectionView reloadData];
    } else if ([[notification name] isEqualToString:@"ChangedSoldNotification"]) {
        PostCoreData *notificationPost = [[notification userInfo] objectForKey:@"post"];
        if (notificationPost.sold) {
            [self.activeItems removeObject:notificationPost];
            [self.soldItems addObject:notificationPost];
            self.soldItems = [self sortPostsArray:self.soldItems];
            [self.collectionView reloadData];
        } else {
            [self.soldItems removeObject:notificationPost];
            [self.activeItems addObject:notificationPost];
            self.activeItems = [self sortPostsArray:self.activeItems];
            [self.collectionView reloadData];
        }
    } else if ([[notification name] isEqualToString:@"DoneSavingPostsWatches"]) {
        [self fetchProfileFromCoreData];
    }
}

- (void)fetchProfileFromCoreData {
    self.locationLabel.text = self.user.address;
    self.navigationItem.title = [@"@" stringByAppendingString:self.user.username];
    self.profilePic.layer.cornerRadius = 45;
    self.profilePic.layer.masksToBounds = YES;
    self.usernameLabel.text = self.user.username;
    
    [self setRating];
    
    NSData *imageData = self.user.profilePic;
    [self.profilePic setImage:[UIImage imageNamed:@"item_placeholder"]];
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        [self.profilePic setImage:image];
    }
    
    NSMutableArray *profilePostsArray = [[CoreDataManager shared] getProfilePostsFromCoreDataForUser:self.user];
    
    NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: NO]];
    self.activeItems = [NSMutableArray arrayWithArray:[profilePostsArray filteredArrayUsingPredicate:aPredicate]];
    if (self.activeItems.count == 1) {
        self.activeCountLabel.text = [NSString stringWithFormat:@"%lu Active Item", self.activeItems.count];
    } else {
        self.activeCountLabel.text = [NSString stringWithFormat:@"%lu Active Items", self.activeItems.count];
    }
    
    NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: YES]];
    self.soldItems = [NSMutableArray arrayWithArray:[profilePostsArray filteredArrayUsingPredicate:sPredicate]];
    if (self.soldItems.count == 1) {
        self.soldCountLabel.text = [NSString stringWithFormat:@"%lu Sold Item", self.soldItems.count];
    } else {
        self.soldCountLabel.text = [NSString stringWithFormat:@"%lu Sold Items", self.soldItems.count];
    }
    
    [self.collectionView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)setRating {
    NSMutableArray *reviewsArray = [[CoreDataManager shared] getReviewsFromCoreDataForSeller:self.user];
    float avgRating = 0;
    
    if (reviewsArray.count > 0) {
        for (ReviewCoreData *review in reviewsArray) {
            avgRating += review.rating;
        }
        
        avgRating /= reviewsArray.count;
    }
    
    self.user.rating = avgRating;
    [self saveContext];
    
    if (avgRating == 0) {
        self.ratingLabel.text = @"not yet rated";
    } else {
        self.ratingLabel.text = [NSString stringWithFormat:@"%.02f/5", self.user.rating];
    }
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self.segmentControl selectedSegmentIndex] == 0) {
        return self.activeItems.count;
    } else {
        return self.soldItems.count;
    }
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if ([self.segmentControl selectedSegmentIndex] == 0) {
        PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"active" forIndexPath:indexPath];
        PostCoreData *post = self.activeItems[indexPath.item];
        cell.post = post;
        return cell;
    } else {
        PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sold" forIndexPath:indexPath];
        PostCoreData *post = self.soldItems[indexPath.item];
        cell.post = post;
        return cell;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    CGFloat posterPerLine = 2;
    CGFloat itemWidth = (self.collectionView.frame.size.width - layout.minimumInteritemSpacing * (posterPerLine - 1)) / posterPerLine;
    CGFloat itemHeight = itemWidth;
    return CGSizeMake(itemWidth, itemHeight);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToDetails"]) {
        PostCollectionViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:tappedCell];
        PostCoreData *post;
        
        if ([self.segmentControl selectedSegmentIndex] == 0) {
            post = self.activeItems[indexPath.row];
        } else {
            post = self.soldItems[indexPath.row];
        }
        
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.post = post;
    } else if ([segue.identifier isEqualToString:@"segueToEditProfile"]) {
        EditProfileVC *editProfileViewController = [segue destinationViewController];
        editProfileViewController.delegate = self;
        editProfileViewController.user = self.user;
    } else if ([segue.identifier isEqualToString:@"sendMsg"]) {
        MessageViewController *msgViewController = [segue destinationViewController];
        msgViewController.user = self.user;
    } else if ([segue.identifier isEqualToString:@"segueToComposeReview"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ComposeReviewViewController *composeReviewViewController = (ComposeReviewViewController *) navigationController.topViewController;
        composeReviewViewController.seller = self.user;
    } else if ([segue.identifier isEqualToString:@"segueToReviews"]) {
        SellerReviewsViewController *sellerReviewsViewController = [segue destinationViewController];
        sellerReviewsViewController.sellerCoreData = self.user;
    }
}

- (IBAction)logout:(id)sender {
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error logging out!: %@", error.localizedDescription);
        } else {
            [self deleteAllCoreData];
        }
    }];
    
    SignInVC *signInVC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"SignInVC"];
    
    [self presentViewController:signInVC animated:YES completion:nil];
}

- (IBAction)changedSegment:(id)sender {
    [self.collectionView reloadData];
}

- (void)updateEditProfileData:(nonnull UIViewController *)viewController {
    EditProfileVC *editProfileViewController = (EditProfileVC *)viewController;
    self.usernameLabel.text = editProfileViewController.user.username;
    self.locationLabel.text = editProfileViewController.user.address;
    self.profilePic.image = [UIImage imageWithData:editProfileViewController.user.profilePic];
    self.navigationItem.title = [@"@" stringByAppendingString:editProfileViewController.user.username];
}

- (void)deleteAllCoreData {
    NSFetchRequest *requestConversations = [[NSFetchRequest alloc] initWithEntityName:@"ConversationCoreData"];
    NSBatchDeleteRequest *deleteConversations = [[NSBatchDeleteRequest alloc] initWithFetchRequest:requestConversations];
    NSError *deleteConversationsError = nil;
    [self.context executeRequest:deleteConversations error:&deleteConversationsError];
    
    NSFetchRequest *requestUsers = [[NSFetchRequest alloc] initWithEntityName:@"UserCoreData"];
    NSBatchDeleteRequest *deleteUsers = [[NSBatchDeleteRequest alloc] initWithFetchRequest:requestUsers];
    NSError *deleteUsersError = nil;
    [self.context executeRequest:deleteUsers error:&deleteUsersError];
    
    NSFetchRequest *requestPosts = [[NSFetchRequest alloc] initWithEntityName:@"PostCoreData"];
    NSBatchDeleteRequest *deletePosts = [[NSBatchDeleteRequest alloc] initWithFetchRequest:requestPosts];
    NSError *deletePostsError = nil;
    [self.context executeRequest:deletePosts error:&deletePostsError];
    
    NSFetchRequest *requestReviews = [[NSFetchRequest alloc] initWithEntityName:@"ReviewCoreData"];
    NSBatchDeleteRequest *deleteReviews = [[NSBatchDeleteRequest alloc] initWithFetchRequest:requestReviews];
    NSError *deleteReviewsError = nil;
    [self.context executeRequest:deleteReviews error:&deleteReviewsError];
}

- (void)saveContext {
    NSError *error = nil;
    if ([self.context hasChanges] && ![self.context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

- (NSMutableArray *)sortPostsArray:(NSMutableArray *)postsArray {
    NSArray *sortedResults = [postsArray sortedArrayUsingComparator:^NSComparisonResult(id firstObj, id secondObj) {
        PostCoreData *firstPost = (PostCoreData *)firstObj;
        PostCoreData *secondPost = (PostCoreData *)secondObj;
        
        if ([firstPost.createdAt compare:secondPost.createdAt] == NSOrderedDescending) {
            return NSOrderedDescending;
        } else if ([firstPost.createdAt compare:secondPost.createdAt] == NSOrderedAscending) {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
    }];
    
    return [NSMutableArray arrayWithArray:sortedResults];
}

@end
