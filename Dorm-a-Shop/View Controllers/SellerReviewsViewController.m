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
#import "ParseManager.h"
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
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedWatchNotification" object:nil];
    
    //[self fetchReviewsFromCoreData];
    [self createRefreshControl];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"DidReviewNotification"]) {
        ReviewCoreData *notificationReview = [[notification userInfo] objectForKey:@"review"];
        [self.reviewsArray insertObject:notificationReview atIndex:0];
    }
}

- (void)createRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(queryReviewsFromParse) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void)queryReviewsFromParse {
    User *seller = (User *)[PFObject objectWithoutDataWithClassName:@"User" objectId:self.sellerCoreData.objectId];
    [[ParseManager shared] queryReviewsForSeller:seller withCompletion:^(NSMutableArray * _Nonnull reviews, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"Error querying reviews! %@", error.localizedDescription);
        } else {
            //self.post
        }
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
