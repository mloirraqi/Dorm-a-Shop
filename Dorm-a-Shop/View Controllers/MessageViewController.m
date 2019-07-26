//
//  MessageViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "MessageViewController.h"
#import "ChatCell.h"
@import Parse;
@import TwilioChatClient;

@interface MessageViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *messages;
@property (weak, nonatomic) IBOutlet UITextField *msgInput;

@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.navigationItem.title = [@"@" stringByAppendingString:self.receiver.username];
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:true];
}

- (void)onTimer {
    PFQuery *sentQuery = [PFQuery queryWithClassName:@"Messages"];
    [sentQuery whereKey:@"receiver" equalTo:self.receiver];
    [sentQuery whereKey:@"sender" equalTo:[PFUser currentUser]];
    
    PFQuery *recQuery = [PFQuery queryWithClassName:@"Messages"];
    [recQuery whereKey:@"receiver" equalTo:[PFUser currentUser]];
    [recQuery whereKey:@"sender" equalTo:self.receiver];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[sentQuery, recQuery]];
    [query orderByAscending:@"createdAt"];
    [query includeKey:@"sender"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *chats, NSError *error) {
        if (chats != nil) {
            self.messages = [NSMutableArray arrayWithArray:chats];
            [self.tableView reloadData];
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


- (IBAction)sendMsg:(id)sender {
    if (!self.convo) {
        PFQuery *sentQuery = [PFQuery queryWithClassName:@"Convos"];
        [sentQuery whereKey:@"sender" equalTo:[PFUser currentUser]];
        [sentQuery whereKey:@"receiver" equalTo:self.receiver];
        
        
        PFQuery *recQuery = [PFQuery queryWithClassName:@"Convos"];
        [recQuery whereKey:@"receiver" equalTo:[PFUser currentUser]];
        [recQuery whereKey:@"sender" equalTo:self.receiver];
        
        PFQuery *query = [PFQuery orQueryWithSubqueries:@[sentQuery, recQuery]];
        
        __weak MessageViewController *weakSelf = self;
        [query findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable messages, NSError * _Nullable error) {
            if (messages.count) {
                weakSelf.convo = messages[0];
            } else {
                PFObject *convo = [PFObject objectWithClassName:@"Convos"];
                convo[@"sender"] = [PFUser currentUser];
                convo[@"receiver"] = self.receiver;
                
                __weak MessageViewController *weakSelf = self;
                [convo saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if (succeeded) {
                        weakSelf.convo = convo;
                    } else {
                        NSLog(@"%@", error.localizedDescription);
                    }
                }];
            }
        }];
    }
    
    PFObject *message = [PFObject objectWithClassName:@"Messages"];
    message[@"sender"] = [PFUser currentUser];
    message[@"receiver"] = self.receiver;
    message[@"text"] = self.msgInput.text;
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
        if (succeeded) {
            NSLog(@"The message was saved!");
        } else {
            NSLog(@"Problem saving message: %@", error.localizedDescription);
        }
    }];
    
    self.convo[@"lastText"] = self.msgInput.text;
    [self.convo saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
        if (succeeded) {
            NSLog(@"The convos class was updated!");
        } else {
            NSLog(@"Problem updating convos class: %@", error.localizedDescription);
        }
    }];
    
    self.msgInput.text = @"";
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCell"];
    PFObject *chat = self.messages[indexPath.row];
    cell.chat = chat;
    [cell showMsg];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

@end
