//
//  HomeScreenViewController.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "QuartzCore/QuartzCore.h"
#import "PostCoreData+CoreDataClass.h"
#import "HomeScreenViewController.h"
#import "PostTableViewCell.h"
#import "Post.h"
#import "UploadViewController.h"
#import "DetailsViewController.h"
#import "SignInVC.h"
#import "AppDelegate.h"
#import "LocationManager.h"
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
#import "NSNotificationCenter+MainThread.h"
@import Parse;

@interface HomeScreenViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@property (strong, nonatomic) NSMutableArray *postsArray;
@property (strong, nonatomic) NSMutableArray *hotArray;

@property (strong, nonatomic) NSMutableArray *filteredPosts;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@property (weak, nonatomic) IBOutlet UITableView *categoryTable;
@property (weak, nonatomic) IBOutlet UITableView *conditionTable;
@property (weak, nonatomic) IBOutlet UITableView *pricesTable;
@property (weak, nonatomic) IBOutlet UITableView *hotnessTable;
@property (strong, nonatomic) NSArray *categories;
@property (strong, nonatomic) NSArray *conditions;
@property (strong, nonatomic) NSArray *prices;
@property (strong, nonatomic) NSArray *pricesInt;
@property (strong, nonatomic) NSArray *hotNess;
@property (weak, nonatomic) IBOutlet UIButton *conditionButton;
@property (weak, nonatomic) IBOutlet UIButton *categoryButton;
@property (weak, nonatomic) IBOutlet UIButton *pricesButton;
@property (weak, nonatomic) IBOutlet UIButton *hotnessButton;
@property NSNumber *limit;
@end

@implementation HomeScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.searchBar.delegate = self;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    
    self.categories =@[@"All", @"Other", @"Furniture", @"Books", @"Stationary", @"Clothes", @"Electronics", @"Accessories"];
    self.conditions = @[@"All", @"New", @"Nearly New", @"Used"];
    self.prices = @[@"All", @"<$25", @"<$50", @"<$100"];
    self.pricesInt = @[@0, @25, @50, @100];
    self.hotNess = @[@"All Items", @"Hot Items"];
    
    NSArray *tables = @[self.categoryTable, self.conditionTable, self.pricesTable, self.hotnessTable];
    for (UITableView *table in tables) {
        table.dataSource = self;
        table.delegate = self;
        table.layer.borderColor = [[UIColor grayColor] CGColor];
        table.layer.borderWidth = 1.0;
        table.hidden = YES;
    }
    
    NSArray *buttons = @[self.categoryButton, self.conditionButton, self.pricesButton, self.hotnessButton];
    for (UIButton *button in buttons) {
        button.layer.borderWidth = 1.0f;
        button.layer.borderColor = [UIColor grayColor].CGColor;
        button.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedWatchNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"ChangedSoldNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DidUploadNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DoneSavingPostsWatches" object:nil];
    
    [self fetchActivePostsFromCoreData];
    [self createRefreshControl];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"ChangedWatchNotification"]) {
        PostCoreData *notificationPost = [[notification userInfo] objectForKey:@"post"];
        NSUInteger postIndexRow = [self.postsArray indexOfObject:notificationPost];
        NSIndexPath *postIndexPath = [NSIndexPath indexPathForRow:postIndexRow inSection:0];
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[postIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    } else if ([[notification name] isEqualToString:@"ChangedSoldNotification"]) {
        PostCoreData *notificationPost = [[notification userInfo] objectForKey:@"post"];
        if (notificationPost.sold) {
            [self.postsArray removeObject:notificationPost];
            [self.tableView reloadData];
        } else {
            [self.postsArray addObject:notificationPost];
            self.postsArray = [self sortPostsArray:self.postsArray];
            [self.tableView reloadData];
        }
    } else if ([[notification name] isEqualToString:@"DidUploadNotification"]) {
        PostCoreData *notificationPost = [[notification userInfo] objectForKey:@"post"];
        [self.postsArray insertObject:notificationPost atIndex:0];
        [self.tableView reloadData];
    } else if ([[notification name] isEqualToString:@"DoneSavingPostsWatches"]) {
        [self fetchActivePostsFromCoreData];
    }
}

- (void)createRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(queryActivePostsFromParse) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void)queryActivePostsFromParse {
    __weak HomeScreenViewController *weakSelf = self;
    [[ParseDatabaseManager shared] queryAllPostsWithinKilometers:5 withCompletion:^(NSMutableArray * _Nonnull postsArray, NSMutableArray * _Nonnull hotArray, NSError * _Nonnull error) {
        if (postsArray) {
            NSPredicate *activePostsPredicate = [NSPredicate predicateWithFormat:@"SELF.sold == %@", [NSNumber numberWithBool: NO]];
            NSMutableArray *activePosts = [NSMutableArray arrayWithArray:[postsArray filteredArrayUsingPredicate:activePostsPredicate]];
            weakSelf.postsArray = activePosts;
            weakSelf.hotArray = hotArray;
            [weakSelf filterPosts];
            [weakSelf.tableView reloadData];
            [weakSelf.refreshControl endRefreshing];
        }
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DidPullActivePosts" object:nil];
    }];
}

- (void)fetchActivePostsFromCoreData {
    self.hotArray = [[CoreDataManager shared] getHotPostsFromCoreData];
    self.postsArray = [[CoreDataManager shared] getActivePostsFromCoreData];
    [self filterPosts];
    [self.tableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DidPullActivePosts" object:nil];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
    PostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostTableViewCell"];
        PostCoreData *post = self.filteredPosts[indexPath.row];
        cell.post = post;
        if([self.hotArray containsObject:post]) {
            cell.hotnessLabel.hidden = NO;
        }
        return cell;
    } else if (tableView == self.categoryTable) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = self.categories[indexPath.row];
        [cell.textLabel setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightThin]];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        return cell;
    } else if (tableView == self.conditionTable) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = self.conditions[indexPath.row];
        [cell.textLabel setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightThin]];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        return cell;
    } else if (tableView == self.pricesTable) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = self.prices[indexPath.row];
        [cell.textLabel setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightThin]];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        return cell;
    } else {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = self.hotNess[indexPath.row];
        [cell.textLabel setFont:[UIFont systemFontOfSize:12 weight:UIFontWeightThin]];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
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
    } else if (tableView == self.pricesTable) {
        return self.prices.count;
    } else {
        return self.hotNess.count;
    }
}

- (void)didUpload:(PostCoreData *)post {
    [self.postsArray insertObject:post atIndex:0];
    [self filterPosts];
}

- (void)updateDetailsData:(UIViewController *)viewController {
    [self filterPosts];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"segueToDetails"]) {
        PostTableViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        PostCoreData *post = self.filteredPosts[indexPath.row];
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.indexPath = indexPath;
        detailsViewController.post = post;
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
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
    if([[self.hotnessButton currentTitle] isEqual: @"All Items"]) {
        self.filteredPosts = self.postsArray;
    } else {
        self.filteredPosts = self.hotArray;
    }
    if (self.searchBar.text.length != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PostCoreData *post, NSDictionary *bindings) {
            return ([post.title localizedCaseInsensitiveContainsString:self.searchBar.text] || [post.caption localizedCaseInsensitiveContainsString:self.searchBar.text]);
        }];
        self.filteredPosts = [NSMutableArray arrayWithArray:[self.filteredPosts filteredArrayUsingPredicate:predicate]];
    }
    
    if (![[self.categoryButton currentTitle] isEqual: @"Category: All"]) {
        NSPredicate *caPredicate = [NSPredicate predicateWithBlock:^BOOL(PostCoreData *post, NSDictionary *bindings) {
            return ([post.category isEqualToString:[self.categoryButton currentTitle]]);
        }];
        self.filteredPosts = [NSMutableArray arrayWithArray:[self.filteredPosts filteredArrayUsingPredicate:caPredicate]];
    }
    
    if (![[self.conditionButton currentTitle] isEqual: @"Condition: All"]) {
        NSPredicate *coPredicate = [NSPredicate predicateWithBlock:^BOOL(PostCoreData *post, NSDictionary *bindings) {
            return ([post.condition isEqualToString:[self.conditionButton currentTitle]]);
        }];
        self.filteredPosts = [NSMutableArray arrayWithArray:[self.filteredPosts filteredArrayUsingPredicate:coPredicate]];
    }
    
    if (![[self.pricesButton currentTitle] isEqual: @"Price: All"]) {
        NSPredicate *pPredicate = [NSPredicate predicateWithBlock:^BOOL(PostCoreData *post, NSDictionary *bindings) {
            return (post.price <= self.limit.intValue);
        }];
        self.filteredPosts = [NSMutableArray arrayWithArray:[self.filteredPosts filteredArrayUsingPredicate:pPredicate]];
    }
    
    [self.tableView reloadData];
}

- (IBAction)categoryChange:(id)sender {
    if (self.categoryTable.hidden) {
        self.categoryTable.hidden = NO;
        self.hotnessTable.hidden = YES;
        self.pricesTable.hidden = YES;
        self.conditionTable.hidden = YES;
    } else {
        self.categoryTable.hidden = YES;
    }
}

- (IBAction)conditionChange:(id)sender {
    if (self.conditionTable.hidden) {
        self.conditionTable.hidden = NO;
        self.categoryTable.hidden = YES;
        self.hotnessTable.hidden = YES;
        self.pricesTable.hidden = YES;
    } else {
        self.conditionTable.hidden = YES;
    }
}

- (IBAction)pricesChange:(id)sender {
    if (self.pricesTable.hidden) {
        self.pricesTable.hidden = NO;
        self.conditionTable.hidden = YES;
        self.categoryTable.hidden = YES;
        self.hotnessTable.hidden = YES;
    } else {
        self.pricesTable.hidden = YES;
    }
}

- (IBAction)hotnessChange:(id)sender {
    if (self.hotnessTable.hidden) {
        self.hotnessTable.hidden = NO;
        self.pricesTable.hidden = YES;
        self.conditionTable.hidden = YES;
        self.categoryTable.hidden = YES;
    } else {
        self.hotnessTable.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.categoryTable) {
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
    } else if (tableView == self.pricesTable) {
        self.pricesTable.hidden = YES;
        if (indexPath.row == 0) {
            [self.pricesButton setTitle:@"Price: All" forState:UIControlStateNormal];
        } else {
            [self.pricesButton setTitle:self.prices[indexPath.row] forState:UIControlStateNormal];
            self.limit = self.pricesInt[indexPath.row];
        }
    } else if (tableView == self.hotnessTable) {
        self.hotnessTable.hidden = YES;
        [self.hotnessButton setTitle:self.hotNess[indexPath.row] forState:UIControlStateNormal];
    }
    
    [self filterPosts];
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
    
    return [NSMutableArray arrayWithArray:sortedResults];
}

@end
