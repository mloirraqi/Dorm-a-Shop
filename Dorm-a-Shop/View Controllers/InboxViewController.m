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
#import "PostManager.h"
#import "AppDelegate.h"
@import Parse;

@interface InboxViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *convos;

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableArray *users;
@property (strong, nonatomic) NSMutableArray *pfusers;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.users = [[NSMutableArray alloc] init];
    self.pfusers = [[NSMutableArray alloc] init];
    
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    self.context = self.appDelegate.persistentContainer.viewContext;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchUsers) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
//    [self fetchUsers];
    [self fetchConvosFromCoreData];
}

- (void)fetchConvosFromCoreData {
    self.convos = [[PostManager shared] getAllConvosFromCoreData];
    [self.tableView reloadData];
}

// To do - rewrite refresh function after fixing conversationcoredata bug
- (void)fetchUsers {
    __weak InboxViewController *weakSelf = self;
    [[PostManager shared] queryConversationsFromParseWithCompletion:^(NSMutableArray<ConversationCoreData *> * _Nonnull conversations, NSError * _Nonnull error) {
        weakSelf.convos = conversations;
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    ConversationCoreData *convoCoreData = self.convos[indexPath.row];
    UserCoreData *user = convoCoreData.sender;
    cell.user = user;
    cell.convo = convoCoreData;
    [cell setUser];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.convos.count;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"sendMsg"]) {
        UserCell *tappedCell = sender;
        MessageViewController *profileViewController = [segue destinationViewController];
        profileViewController.receiver = tappedCell.convo.pfuser;
        profileViewController.convo = tappedCell.convo.convo;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

@end
