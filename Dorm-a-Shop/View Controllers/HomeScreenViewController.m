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
#import "PostManager.h"
#import "LocationManager.h"
@import Parse;

@interface HomeScreenViewController () <DetailsViewControllerDelegate, UploadViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSMutableArray *postsArray;
@property (strong, nonatomic) NSMutableArray *filteredPosts;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSString *className;

@property (weak, nonatomic) IBOutlet UITableView *categoryTable;
@property (weak, nonatomic) IBOutlet UITableView *conditionTable;
@property (weak, nonatomic) IBOutlet UITableView *timesTable;
@property (weak, nonatomic) IBOutlet UITableView *distanceTable;
@property (strong, nonatomic) NSArray *categories;
@property (strong, nonatomic) NSArray *conditions;
@property (strong, nonatomic) NSArray *times;
@property (strong, nonatomic) NSArray *distances;
@property (weak, nonatomic) IBOutlet UIButton *conditionButton;
@property (weak, nonatomic) IBOutlet UIButton *categoryButton;
@property (weak, nonatomic) IBOutlet UIButton *timesButton;
@property (weak, nonatomic) IBOutlet UIButton *distanceButton;

@end

@implementation HomeScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.className = @"HomeScreenViewController";
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.searchBar.delegate = self;
    self.categoryTable.dataSource = self;
    self.categoryTable.delegate = self;
    self.conditionTable.dataSource = self;
    self.conditionTable.delegate = self;
    self.timesTable.dataSource = self;
    self.timesTable.delegate = self;
    self.distanceTable.dataSource = self;
    self.distanceTable.delegate = self;
    self.categories = @[@"All", @"Furniture", @"Books", @"Beauty", @"Other"];
    self.conditions = @[@"All", @"New", @"Nearly New", @"Old"];
    self.times = @[@"All", @"<1 Day", @"<1 Week", @"<1 Month"];
    self.distances = @[@"All", @"<1 Miles", @"<3 Miles", @"<5 Miles"];
    self.categoryTable.hidden = YES;
    self.conditionTable.hidden = YES;
    self.timesTable.hidden = YES;
    self.distanceTable.hidden = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedWatchNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedSoldNotification" object:nil];
    
    [self fetchPosts];
    [self createRefreshControl];
}

- (IBAction)chatButton:(id)sender {
   [self performSegueWithIdentifier:@"chatBox" sender:nil];
}


- (void)receiveNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"ChangedWatchNotification"]) {
        Post *notificationPost = [[notification userInfo] objectForKey:@"post"];
        NSUInteger postIndexRow = [self.postsArray indexOfObject:notificationPost];
        NSIndexPath *postIndexPath = [NSIndexPath indexPathForRow:postIndexRow inSection:0];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[postIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
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
    
    CLLocation *currentLocation = [[LocationManager sharedInstance] currentLocation];
    PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
    
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"Location" nearGeoPoint:location withinKilometers:5.0];

    PFQuery *postQuery = [Post query];
    [postQuery orderByDescending:@"createdAt"];
    [postQuery includeKey:@"author"];
    [postQuery whereKey:@"sold" equalTo:[NSNumber numberWithBool: NO]];
    [postQuery whereKey:@"author" matchesQuery:userQuery];
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
    if (tableView == self.tableView) {
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostTableViewCell"];
        Post *post = self.filteredPosts[indexPath.row];
        cell.post = post;
        return cell;
    } else if (tableView == self.categoryTable) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = self.categories[indexPath.row];
        return cell;
    } else if (tableView == self.conditionTable) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = self.conditions[indexPath.row];
        return cell;
    } else if (tableView == self.timesTable) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = self.times[indexPath.row];
        [cell.textLabel setFont:[UIFont systemFontOfSize:12]];
        return cell;
    } else {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = self.distances[indexPath.row];
        [cell.textLabel setFont:[UIFont systemFontOfSize:12]];
        return cell;
    }
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return self.filteredPosts.count;
    } else if (tableView == self.categoryTable) {
        return self.categories.count;
    } else if (tableView == self.conditionTable) {
        return self.conditions.count;
    } else if (tableView == self.timesTable) {
        return self.times.count;
    } else {
        return self.distances.count;
    }
}

- (void)didUpload:(Post *)post {
    [self.postsArray insertObject:post atIndex:0];
    [self filterPosts];
}

- (void)updateDetailsData:(UIViewController *)viewController {
    /*COMMENTS ARE STILL NEEDED, BUT WILL BE CLEANED UP LATER
     DetailsViewController *detailsViewController = (DetailsViewController *)viewController;
    if (detailsViewController.itemStatusChanged) {
        if (detailsViewController.post.sold == YES) {
            [self.postsArray removeObject:detailsViewController.post];
            [self filterPosts];
        }
    }*/
    [self filterPosts];
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
    self.filteredPosts = self.postsArray;
    
    if (self.searchBar.text.length != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(Post *post, NSDictionary *bindings) {
            return ([post.title localizedCaseInsensitiveContainsString:self.searchBar.text] || [post.caption localizedCaseInsensitiveContainsString:self.searchBar.text]);
        }];
        self.filteredPosts = [NSMutableArray arrayWithArray:[self.filteredPosts filteredArrayUsingPredicate:predicate]];
    }
    
    if (![[self.categoryButton currentTitle] isEqual: @"Category: All"]) {
        NSPredicate *caPredicate = [NSPredicate predicateWithBlock:^BOOL(Post *post, NSDictionary *bindings) {
            return ([post.category isEqualToString:[self.categoryButton currentTitle]]);
        }];
        self.filteredPosts = [NSMutableArray arrayWithArray:[self.filteredPosts filteredArrayUsingPredicate:caPredicate]];
    }
    
    if (![[self.conditionButton currentTitle] isEqual: @"Condition: All"]) {
        NSPredicate *coPredicate = [NSPredicate predicateWithBlock:^BOOL(Post *post, NSDictionary *bindings) {
            return ([post.condition isEqualToString:[self.conditionButton currentTitle]]);
        }];
        self.filteredPosts = [NSMutableArray arrayWithArray:[self.filteredPosts filteredArrayUsingPredicate:coPredicate]];
    }
    
    [self.tableView reloadData];
}

- (IBAction)categoryChange:(id)sender {
    if(self.categoryTable.hidden) {
        self.categoryTable.hidden = NO;
    } else {
        self.categoryTable.hidden = YES;
    }
}

- (IBAction)conditionChange:(id)sender {
    if(self.conditionTable.hidden) {
        self.conditionTable.hidden = NO;
    } else {
        self.conditionTable.hidden = YES;
    }
}

- (IBAction)timesChange:(id)sender {
    if(self.timesTable.hidden) {
        self.timesTable.hidden = NO;
    } else {
        self.timesTable.hidden = YES;
    }
}

- (IBAction)distancesChange:(id)sender {
    if(self.distanceTable.hidden) {
        self.distanceTable.hidden = NO;
    } else {
        self.distanceTable.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if(tableView == self.categoryTable) {
        self.categoryTable.hidden = YES;
        if (indexPath.row == 0) {
            [self.categoryButton setTitle:@"Category: All" forState:UIControlStateNormal];
            
        } else {
            [self.categoryButton setTitle:self.categories[indexPath.row] forState:UIControlStateNormal];
        }
    } else if (tableView == self.conditionTable) {
        self.conditionTable.hidden = YES;
        if (indexPath.row == 0) {
            [self.conditionButton setTitle:@"Condition: All" forState:UIControlStateNormal];
            
        } else {
            [self.conditionButton setTitle:self.conditions[indexPath.row] forState:UIControlStateNormal];
        }
    } else if (tableView == self.timesTable) {
        self.timesTable.hidden = YES;
        [self.timesButton setTitle:self.times[indexPath.row] forState:UIControlStateNormal];
    } else if (tableView == self.distanceTable) {
        self.distanceTable.hidden = YES;
        [self.distanceButton setTitle:self.distances[indexPath.row] forState:UIControlStateNormal];
    }
    [self filterPosts];
}

@end
