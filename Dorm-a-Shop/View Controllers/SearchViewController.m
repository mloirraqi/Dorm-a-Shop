//
//  SearchViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "SearchViewController.h"
#import "UserCell.h"
#import "ProfileViewController.h"
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"
@import Parse;

@interface SearchViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) NSMutableArray *filteredUsers;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.searchBar.delegate = self;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(queryUsersFromParse) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DoneSavingUsers" object:nil];
    
    [self fetchUsersFromCoreData];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"DoneSavingUsers"]) {
        [self fetchUsersFromCoreData];
    }
}

- (void)fetchUsersFromCoreData {
    self.users = [[CoreDataManager shared] getAllUsersInRadiusFromCoreData];
    [self filterUsers];
    [self.tableView reloadData];
}

- (void)queryUsersFromParse {
    __weak SearchViewController *weakSelf = self;
    [[ParseDatabaseManager shared] queryAllUsersWithinKilometers:5.0 withCompletion:^(NSMutableArray<UserCoreData *> * users, NSError * error) {
        if (users) {
            weakSelf.users = [NSMutableArray arrayWithArray:users];
            [weakSelf filterUsers];
            [weakSelf.tableView reloadData];
            [self.refreshControl endRefreshing];
        } else {
            NSLog(@"😫😫😫 Error getting home timeline: %@", error.localizedDescription);
        }
    }];
}

- (void)filterUsers {
    self.filteredUsers = self.users;
    if (self.searchBar.text.length != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(UserCoreData *user, NSDictionary *bindings) {
            return ([user.username localizedCaseInsensitiveContainsString:self.searchBar.text]);
        }];
        self.filteredUsers = [NSMutableArray arrayWithArray:[self.filteredUsers filteredArrayUsingPredicate:predicate]];
    }
    [self.tableView reloadData];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    UserCoreData *user = self.filteredUsers[indexPath.row];
    cell.user = user;
    [cell setUser];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredUsers.count;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self filterUsers];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.showsCancelButton = NO;
    self.searchBar.text = @"";
    [self.searchBar resignFirstResponder];
    self.filteredUsers = self.users;
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"userDeets"]) {
        UserCell *tappedCell = sender;
        ProfileViewController *profileViewController = [segue destinationViewController];
        profileViewController.user = (UserCoreData *)tappedCell.user;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
