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
#import "ConversationCoreData+CoreDataClass.h"
@import Parse;

@interface InboxViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *convos;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation InboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchConvos) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void)viewDidAppear:(BOOL)animated {
    [self fetchConvosFromCoreData];
}

- (void)fetchConvosFromCoreData {
    self.convos = [[PostManager shared] getAllConvosFromCoreData];
    [self.tableView reloadData];
}

- (void)fetchConvos {
    __weak InboxViewController *weakSelf = self;
    [[PostManager shared] queryConversationsFromParseWithCompletion:^(NSMutableArray<ConversationCoreData *> * _Nonnull conversations, NSError * _Nonnull error) {
        weakSelf.convos = conversations;
        [weakSelf.tableView reloadData];
        [weakSelf.refreshControl endRefreshing];
    }];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    ConversationCoreData *convoCoreData = self.convos[indexPath.row];
    cell.convo = convoCoreData;
    cell.user = convoCoreData.sender;
    [cell setUser];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.convos.count;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"sendMsg"]) {
        UserCell *tappedCell = sender;
        MessageViewController *msgViewController = [segue destinationViewController];
        msgViewController.user = tappedCell.convo.sender;
        msgViewController.conversationCoreData = tappedCell.convo;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

@end
