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
@import Parse;

@interface SearchViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) NSMutableArray *filteredUsers;
@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.searchBar.delegate = self;
    [self fetchUsers];
}

- (void)fetchUsers {
    PFQuery *userQuery = [PFQuery queryWithClassName:@"_User"];
    [userQuery orderByAscending:@"username"];

    __weak SearchViewController *weakSelf = self;
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable users, NSError * _Nullable error) {
        if (users) {
            weakSelf.users = [NSMutableArray arrayWithArray:users];
            [weakSelf filterUsers];
            [weakSelf.tableView reloadData];
        } else {
            NSLog(@"😫😫😫 Error getting home timeline: %@", error.localizedDescription);
        }
    }];
}

- (void)filterUsers {
    self.filteredUsers = self.users;
    if (self.searchBar.text.length != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(PFObject *user, NSDictionary *bindings) {
            return ([user[@"username"] localizedCaseInsensitiveContainsString:self.searchBar.text]);
        }];
        self.filteredUsers = [NSMutableArray arrayWithArray:[self.filteredUsers filteredArrayUsingPredicate:predicate]];
    }
    [self.tableView reloadData];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    PFObject *user = self.filteredUsers[indexPath.row];
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
        profileViewController.user = (PFUser *) tappedCell.user;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
