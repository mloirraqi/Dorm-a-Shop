//
//  SellerReviewsViewController.m
//  
//
//  Created by ilanashapiro on 8/1/19.
//

#import "SellerReviewsViewController.h"
#import "ReviewCoreData+CoreDataClass.h"
#import "AppDelegate.h"
#import "ReviewTableViewCell.h"
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
#import "User.h"

@interface SellerReviewsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSMutableArray *reviewsArray;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end

@implementation SellerReviewsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DidReviewNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DoneSavingReviews" object:nil];
    
    [self fetchReviewsFromCoreData];
    [self createRefreshControl];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"DidReviewNotification"]) {
        ReviewCoreData *notificationReview = [[notification userInfo] objectForKey:@"review"];
        [self.reviewsArray insertObject:notificationReview atIndex:0];
        [self.tableView reloadData];
    } else if ([[notification name] isEqualToString:@"DoneSavingReviews"]) {
        [self fetchReviewsFromCoreData];
    }
}

- (void)fetchReviewsFromCoreData {
    self.reviewsArray = [[CoreDataManager shared] getReviewsFromCoreDataForSeller:self.sellerCoreData];
    [self.tableView reloadData];
}

- (void)createRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(queryReviewsFromParse) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void)queryReviewsFromParse {
    User *seller = (User *)[PFObject objectWithoutDataWithClassName:@"_User" objectId:self.sellerCoreData.objectId];
    
    [[ParseDatabaseManager shared] queryReviewsForSeller:seller withCompletion:^(NSMutableArray * _Nonnull reviews, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error querying reviews! %@", error.localizedDescription);
        } else {
            self.reviewsArray = reviews;
            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];
    }];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    ReviewTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReviewTableViewCell"];
    ReviewCoreData *review = self.reviewsArray[indexPath.row];
    cell.review = review;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reviewsArray.count;
}

@end
