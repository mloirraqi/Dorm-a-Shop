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
#import "ParseManager.h"
#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "MessageViewController.h"
#import "ComposeReviewViewController.h"
#import "SellerReviewsViewController.h"
@import Parse;

@interface ProfileViewController () <EditProfileViewControllerDelegate, DetailsViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *activeItems;
@property (nonatomic, strong) NSMutableArray *soldItems;
@property (nonatomic, strong) NSNumber *selectedSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *activeCount;
@property (weak, nonatomic) IBOutlet UILabel *soldCount;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.className = @"ProfileViewController";
    
    if (!self.user) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        self.context = appDelegate.persistentContainer.viewContext;
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
    layout.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DidUploadNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedSoldNotification" object:nil];
    
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
        [self fetchProfileFromCoreData];
    }
}

- (void)fetchProfileFromCoreData {
    self.username.text = self.user.username;
    self.location.text = self.user.address;
    self.navigationItem.title = [@"@" stringByAppendingString:self.user.username];
    self.profilePic.layer.cornerRadius = 40;
    self.profilePic.layer.masksToBounds = YES;
    
    NSData *imageData = self.user.profilePic;
    [self.profilePic setImage:[UIImage imageNamed:@"item_placeholder"]];
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        [self.profilePic setImage:image];
    }

    NSMutableArray *profilePostsArray = [[CoreDataManager shared] getProfilePostsFromCoreDataForUser:self.user];
    
    NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: NO]];
    self.activeItems = [NSMutableArray arrayWithArray:[profilePostsArray filteredArrayUsingPredicate:aPredicate]];
    self.activeCount.text = [NSString stringWithFormat:@"%lu", self.activeItems.count];
    
    NSPredicate *sPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: YES]];
    self.soldItems = [NSMutableArray arrayWithArray:[profilePostsArray filteredArrayUsingPredicate:sPredicate]];
    self.soldCount.text = [NSString stringWithFormat:@"%lu", self.soldItems.count];
    
    [self.collectionView reloadData];
    [self.refreshControl endRefreshing];
}

- (IBAction)changedSegment:(id)sender {
    [self.collectionView reloadData];
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

- (void)updateDetailsData:(UIViewController *)viewController {
    //THIS COMMENTED OUT CODE IS STILL NEEDED FOR OUR REFERENCE AND WILL BE REMOVED ONCE NO LONGER NEEDED

//    DetailsViewController *detailsViewController = (DetailsViewController *)viewController;
//
//    if (detailsViewController.itemStatusChanged) {
//        if (detailsViewController.post.sold == NO) {
//            [self.activeItems insertObject:detailsViewController.post atIndex:0];
//            [self.soldItems removeObject:detailsViewController.post];
//        } else {
//            [self.soldItems insertObject:detailsViewController.post atIndex:0];
//            [self.activeItems removeObject:detailsViewController.post];
//        }
//
//        [self.collectionView reloadData];
//        self.activeCount.text = [NSString stringWithFormat:@"%lu", self.activeItems.count];
//        self.soldCount.text = [NSString stringWithFormat:@"%lu", self.soldItems.count];
//    }
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
        detailsViewController.delegate = self;
        detailsViewController.senderClassName = self.className;
        detailsViewController.post = post;
    } else if ([segue.identifier isEqualToString:@"segueToEditProfile"]) {
        EditProfileVC *editProfileViewController = [segue destinationViewController];
        editProfileViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"sendMsg"]) {
        MessageViewController *msgViewController = [segue destinationViewController];
        msgViewController.receiver = sender;
    } else if ([segue.identifier isEqualToString:@"segueToComposeReview"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        ComposeReviewViewController *composeReviewViewController = (ComposeReviewViewController *) navigationController.topViewController;
        composeReviewViewController.seller = self.user;
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
}

@end
