//
//  HomeScreenViewController.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "WatchListViewController.h"
#import "PostTableViewCell.h"
#import "Post.h"
#import "UploadViewController.h"
#import "DetailsViewController.h"
#import "PostManager.h"
@import Parse;

@interface WatchListViewController () <DetailsViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSMutableArray *postsArray;

@end

@implementation WatchListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedWatchNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedSoldNotification" object:nil];
    
    [self fetchPosts];
    [self createRefreshControl];
}

- (void)receiveNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"ChangedWatchNotification"]) {
        [self.tableView reloadData];
    } else if ([[notification name] isEqualToString:@"ChangedSoldNotification"]) {
        [self fetchPosts];
    }
}

- (void)createRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchPosts) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void)fetchPosts {
    NSMutableArray *activeWatchPosts = [[PostManager shared] getActiveWatchedPostsForCurrentUserFromCoreData];
    self.postsArray = activeWatchPosts;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostTableViewCell"];

    Post *post = self.postsArray[indexPath.row];
    cell.post = post;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postsArray.count;
}

- (void)updateDetailsData:(UIViewController *)viewController {
    DetailsViewController *detailsViewController = (DetailsViewController *)viewController;
    if (detailsViewController.watchStatusChanged) {
        [self.tableView reloadData];
    } else if (detailsViewController.itemStatusChanged) {
        if (detailsViewController.post.sold == YES) {
            [self.postsArray removeObject:detailsViewController.post];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToDetails"]) {
        PostTableViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        Post *post = self.postsArray[indexPath.row];
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.post = post;
        detailsViewController.delegate = self;
    }
}

@end
