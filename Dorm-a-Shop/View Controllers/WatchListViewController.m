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
@property (weak, nonatomic) IBOutlet UIView *nothingWatchedView;
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
        NSLog(@"self.postsArray: %@, notificationPost: %@, class: %@", self.postsArray, notificationPost, [self.postsArray class]);
        if (!notificationPost.watched) {
            [self.postsArray removeObject:notificationPost];
        } else if (!notificationPost.sold) {
            [self.postsArray addObject:notificationPost];
        }
        
        if (self.postsArray.count == 0) {
            [self.nothingWatchedView setHidden:NO];
        } else {
            [self.nothingWatchedView setHidden:YES];
            self.postsArray = [self sortPostsArray:self.postsArray];
            [self.tableView reloadData];
        }
    } else if ([[notification name] isEqualToString:@"DoneSavingPostsWatches"]) {
        [self fetchPostsFromCoreData];
    } else if ([[notification name] isEqualToString:@"ChangedSoldNotification"]) {
        PostCoreData *notificationPost = [[notification userInfo] objectForKey:@"post"];
        if (notificationPost.sold) {
            [self.postsArray removeObject:notificationPost];
            
            if (self.postsArray.count == 0) {
                [self.nothingWatchedView setHidden:NO];
            } else {
                [self.nothingWatchedView setHidden:YES];
                self.postsArray = [self sortPostsArray:self.postsArray];
                [self.tableView reloadData];
            }
        } else {
            [self.postsArray addObject:notificationPost];
            [self.nothingWatchedView setHidden:YES];
            self.postsArray = [self sortPostsArray:self.postsArray];
            [self.tableView reloadData];
        }
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
    
    if (self.postsArray.count == 0) {
        [self.nothingWatchedView setHidden:NO];
    } else {
        [self.nothingWatchedView setHidden:YES];
        //(sorting is done in singleton when only doing a simple fetch)
        [self.tableView reloadData];
    }
    
    [self.refreshControl endRefreshing];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostTableViewCell"];
    PostCoreData *post = self.postsArray[indexPath.row];
    cell.post = post;
    
    NSMutableArray *hotArray = [[CoreDataManager shared] getHotPostsFromCoreData];
    if ([hotArray containsObject:post]) {
        cell.hotnessLabel.hidden = NO;
    }
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.postsArray.count;
}

- (NSMutableArray *)sortPostsArray:(NSMutableArray *)postsArray {
    NSArray *sortedResults = [postsArray sortedArrayUsingComparator:^NSComparisonResult(id firstObj, id secondObj) {
        PostCoreData *firstPost = (PostCoreData *)firstObj;
        PostCoreData *secondPost = (PostCoreData *)secondObj;
        
        if (firstPost.rank > secondPost.rank) {
            return NSOrderedAscending;
        } else if (firstPost.rank > secondPost.rank) {
            return NSOrderedDescending;
        } else if ([firstPost.createdAt compare:secondPost.createdAt] == NSOrderedDescending) {
            return NSOrderedDescending;
        } else if ([firstPost.createdAt compare:secondPost.createdAt] == NSOrderedAscending) {
            return NSOrderedAscending;
        }
        
        return NSOrderedSame;
    }];
    
    return [NSMutableArray arrayWithArray:sortedResults];;
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
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

@end
