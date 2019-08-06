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
#import "ParseDatabaseManager.h"
#import "AppDelegate.h"
#import "CoreDataManager.h"
@import Parse;

@interface WatchListViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DoneSavingPostsWatches" object:nil];
    
    [self fetchPostsFromCoreData];
    [self createRefreshControl];
}

- (void)receiveNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"ChangedWatchNotification"]) {
        PostCoreData *notificationPost = [[notification userInfo] objectForKey:@"post"];
        if (!notificationPost.watched) {
            [self.postsArray removeObject:notificationPost];
        } else if (!notificationPost.sold) {
            [self.postsArray insertObject:notificationPost atIndex:0];
        } else if ([[notification name] isEqualToString:@"DoneSavingPostsWatches"]) {
            [self fetchPostsFromCoreData];
        }
        
        [self.tableView reloadData];
    } else if ([[notification name] isEqualToString:@"ChangedSoldNotification"]) {
        [self fetchPostsFromCoreData];
    }
}

- (void)createRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchPostsFromCoreData) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void)fetchPostsFromCoreData {
    NSMutableArray *activeWatchPosts = [[CoreDataManager shared] getActiveWatchedPostsForCurrentUserFromCoreData];
    self.postsArray = activeWatchPosts;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostTableViewCell"];
    PostCoreData *post = self.postsArray[indexPath.row];
    cell.post = post;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postsArray.count;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToDetails"]) {
        PostTableViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        Post *post = self.postsArray[indexPath.row];
        DetailsViewController *detailsViewController = [segue destinationViewController];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = appDelegate.persistentContainer.viewContext;
        PostCoreData *postCoreData = (PostCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"PostCoreData" withObjectId:post.objectId withContext:context];
        detailsViewController.post = postCoreData;
    }
}

@end
