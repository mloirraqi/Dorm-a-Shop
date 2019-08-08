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
@property (nonatomic, strong) NSMutableArray *matchedUsers;
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
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) AppDelegate *appDelegate;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.className = @"ProfileViewController";
    
    if (!self.user) {
        self.appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        self.context = self.appDelegate.persistentContainer.viewContext;
        self.user = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:PFUser.currentUser.objectId withContext:self.context];
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
    itemSize = CGSizeMake(itemWidth, itemHeight);
    
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
    self.profilePic.layer.cornerRadius = 50;
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
    } else if ([self.segmentControl selectedSegmentIndex] == 1) {
        return self.soldItems.count;
    } else {
        return self.matchedUsers.count;
    }
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if ([self.segmentControl selectedSegmentIndex] == 0) {
        PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"active" forIndexPath:indexPath];
        PostCoreData *post = self.activeItems[indexPath.item];
        cell.post = post;
        return cell;
    } else if ([self.segmentControl selectedSegmentIndex] == 1) {
        PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sold" forIndexPath:indexPath];
        PostCoreData *post = self.soldItems[indexPath.item];
        cell.post = post;
        return cell;
    } else {
        UserCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UserCollectionCell" forIndexPath:indexPath];
        
        NSString* objectId1 = self.matchedUsers[indexPath.row][@"accepted"];
        NSString* objectId2 = self.matchedUsers[indexPath.row][@"userId"];
        
        NSString* objectId = [[PFUser currentUser].objectId isEqualToString:objectId1] ? objectId2 : objectId1;
        
        UserCoreData *userCoreData = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData"
                                                                                            withObjectId:objectId
                                                                                             withContext:self.context];
        cell.user = userCoreData;
        [cell setUser];
        
        cell.username.textColor = [UIColor blackColor];
        cell.locationLabel.textColor = [UIColor blackColor];
        return cell;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.segmentControl selectedSegmentIndex] == 2) {
        CGFloat width = collectionView.frame.size.width/3;
        return CGSizeMake(width, width + 70); //70 is size of two labels
    }
    
    return itemSize;
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
        detailsViewController.senderClassName = self.className;
        detailsViewController.post = post;
    } else if ([segue.identifier isEqualToString:@"segueToEditProfile"]) {
        EditProfileVC *editProfileViewController = [segue destinationViewController];
        editProfileViewController.delegate = self;
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
    
    if ([self.segmentControl selectedSegmentIndex] == 2) { //Matched Users
        
        if (self.matchedUsers.count <= 0) { //Fetch records if empty
            
            __weak ProfileViewController *weakSelf = self;
            
            NSString* userId = self.user.objectId;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(userId = %@ OR accepted = %@) AND matched = 1", userId, userId];
            PFQuery *query = [PFQuery queryWithClassName:@"SwipeRecord" predicate:predicate];
            
            [query findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable swipeRecords, NSError * _Nullable error) {
                if (swipeRecords) {
                    if (swipeRecords.count != 0) { //We will have > 0 count if accepted user and userid matches where clause.
                        NSLog(@"😍 Found %lu records", (unsigned long)swipeRecords.count);
                        weakSelf.matchedUsers = [swipeRecords mutableCopy];
                        [weakSelf.collectionView reloadData];
                    } else {
                        NSLog(@"😫😫😫 No such User Found");
                    }
                } else {
                    NSLog(@"😫😫😫 Error getting User to CheckMatch: %@", error.localizedDescription);
                }
            }];
            
            return;
        }
    }
    
    [self.collectionView reloadData];
}

- (void)updateEditProfileData:(nonnull UIViewController *)editProfileViewController {
    [self fetchProfileFromCoreData];
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
