//
//  InboxViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "InboxViewController.h"
#import "UserCell.h"
#import "MessageViewController.h"
@import Parse;

@interface InboxViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableArray *users;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.users = [[NSMutableArray alloc] init];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchUsers) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    [self fetchUsers];
}

- (void)fetchUsers {
    self.users = [[NSMutableArray alloc] init];
    
    PFQuery *sentQuery = [PFQuery queryWithClassName:@"Convos"];
    [sentQuery whereKey:@"sender" equalTo:[PFUser currentUser]];

    PFQuery *recQuery = [PFQuery queryWithClassName:@"Convos"];
    [recQuery whereKey:@"receiver" equalTo:[PFUser currentUser]];

    PFQuery *query = [PFQuery orQueryWithSubqueries:@[sentQuery, recQuery]];
    [query orderByDescending:@"updatedAt"];
    [query includeKey:@"sender"];
    [query includeKey:@"receiver"];
    
    __weak InboxViewController *weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable messages, NSError * _Nullable error) {
        if (messages) {
            for (PFObject *message in messages) {
                if(![((PFUser *)message[@"sender"]).objectId isEqualToString:PFUser.currentUser.objectId]) {
                    [weakSelf.users addObject:((PFUser *)message[@"sender"])];
                } else {
                    [weakSelf.users addObject:((PFUser *)message[@"receiver"])];
                }
            }
            self.messages = [NSMutableArray arrayWithArray:messages];
            [weakSelf.tableView reloadData];
            [self.refreshControl endRefreshing];
        } else {
            NSLog(@"😫😫😫 Error getting inbox: %@", error.localizedDescription);
        }
    }];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    PFObject *user = self.users[indexPath.row];
    PFObject *convo = self.messages[indexPath.row];
    cell.user = user;
    cell.convo = convo;
    [cell setUser];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"sendMsg"]) {
        UserCell *tappedCell = sender;
        MessageViewController *profileViewController = [segue destinationViewController];
        profileViewController.receiver = (PFUser *) tappedCell.user;
        profileViewController.convo = tappedCell.convo;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

@end
