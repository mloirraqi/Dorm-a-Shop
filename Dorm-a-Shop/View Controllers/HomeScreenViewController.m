//
//  HomeScreenViewController.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "HomeScreenViewController.h"
#import "PostTableViewCell.h"
#import "Post.h"
#import "UploadViewController.h"
#import "DetailsViewController.h"
#import "SignInVC.h"
@import Parse;

@interface HomeScreenViewController () <DetailsViewControllerDelegate, UploadViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSMutableArray *postsArray;
@property (strong, nonatomic) NSMutableArray *filteredPosts;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSString *className;

@end

@implementation HomeScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.className = @"HomeScreenViewController";
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.searchBar.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:@"ChangedWatchNotification"
                                               object:nil];
    
    [self fetchPosts];
    [self createRefreshControl];
}

- (void)receiveNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"ChangedWatchNotification"]) {
        NSString *postOwnerClassName = [[notification userInfo] objectForKey:@"postOwnerClassName"];
        if (![postOwnerClassName isEqualToString:self.className]) {
            Post *notificationPost = [[notification userInfo] objectForKey:@"post"];
            int index = 0;
            for (Post *post in self.postsArray) {
                if ([post.objectId isEqualToString:notificationPost.objectId]) {
                    [self.postsArray replaceObjectAtIndex:index withObject:notificationPost];
                    PostTableViewCell *cellToUpdate = self.postsArray[index];
                    self.watchButton.selected = NO;
                    self.post.watchCount --;
                    [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", self.post.watchCount] forState:UIControlStateNormal];
                }
                index ++;
            }
        }
    }
}

- (void)createRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchPosts) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void)fetchPosts {
    PFQuery *postQuery = [Post query];
    [postQuery orderByDescending:@"createdAt"];
    [postQuery includeKey:@"author"];
    [postQuery whereKey:@"sold" equalTo:[NSNumber numberWithBool: NO]];
    
    __weak HomeScreenViewController *weakSelf = self;
    [postQuery findObjectsInBackgroundWithBlock:^(NSArray<Post *> * _Nullable posts, NSError * _Nullable error) {
        if (posts) {
            weakSelf.postsArray = [NSMutableArray arrayWithArray:posts];
            [weakSelf filterPosts];
            [weakSelf.tableView reloadData];
        } else {
            NSLog(@"😫😫😫 Error getting home timeline: %@", error.localizedDescription);
        }
        [self.refreshControl endRefreshing];
    }];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostTableViewCell"];
    
    Post *post = self.filteredPosts[indexPath.row];
    cell.post = post;
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredPosts.count;
}

- (void)didUpload:(Post *)post {
    [self.postsArray insertObject:post atIndex:0];
    [self filterPosts];
}

- (void)updateDetailsData:(UIViewController *)viewController {
    DetailsViewController *detailsViewController = (DetailsViewController *)viewController;
    if (detailsViewController.watchStatusChanged) {
        [self.tableView reloadData];
    } else if (detailsViewController.itemStatusChanged) {
        if (detailsViewController.post.sold == YES) {
            [self.postsArray removeObject:detailsViewController.post];
            [self filterPosts];
        }
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToUpload"]) {
        UINavigationController *uploadViewNavigationController = [segue destinationViewController];
        UploadViewController *uploadViewController = (UploadViewController *) uploadViewNavigationController.topViewController;
        uploadViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"segueToDetails"]) {
        PostTableViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        Post *post = self.filteredPosts[indexPath.row];
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.indexPath = indexPath;
        detailsViewController.delegate = self;
        detailsViewController.senderClassName = self.className;
        detailsViewController.post = post;
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self filterPosts];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    self.searchBar.text = @"";
    [self.searchBar resignFirstResponder];
    self.filteredPosts = self.postsArray;
    [self.tableView reloadData];
}

- (void)filterPosts {
    if (self.searchBar.text.length != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(Post *post, NSDictionary *bindings) {
            return ([post.title localizedCaseInsensitiveContainsString:self.searchBar.text] || [post.caption localizedCaseInsensitiveContainsString:self.searchBar.text]);
        }];
        self.filteredPosts = [NSMutableArray arrayWithArray:[self.postsArray filteredArrayUsingPredicate:predicate]];
    } else {
        self.filteredPosts = self.postsArray;
    }
    [self.tableView reloadData];
}

@end
