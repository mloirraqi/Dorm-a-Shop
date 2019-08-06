//
//  MessageViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "MessageViewController.h"
#import "ChatCell.h"
#import "AppDelegate.h"
#import "UserCoreData+CoreDataClass.h"
#import "CoreDataManager.h"
@import Parse;
@import TwilioChatClient;

@interface MessageViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *messages;
@property (weak, nonatomic) IBOutlet UITextField *msgInput;
@property (strong, nonatomic) PFUser *receiver;
@property (strong, nonatomic) PFObject *convo;
@property (strong, nonatomic) NSManagedObjectContext *context;

@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.context = appDelegate.persistentContainer.viewContext;
    self.receiver = (PFUser *) [PFObject objectWithoutDataWithClassName:@"_User" objectId:self.user.objectId];
    if(self.conversationCoreData) {
        self.convo = [PFObject objectWithoutDataWithClassName:@"Convos" objectId:self.conversationCoreData.objectId];
    }
    self.navigationItem.title = [@"@" stringByAppendingString:self.user.username];
    
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
    
    __weak MessageViewController *weakSelf = self;
    [query findObjectsInBackgroundWithBlock:^(NSArray *chats, NSError *error) {
        if (chats != nil) {
            weakSelf.messages = [NSMutableArray arrayWithArray:chats];
            PFObject *lastMsg = (PFObject *) [chats lastObject];
            weakSelf.conversationCoreData.updatedAt = lastMsg.createdAt;
            weakSelf.conversationCoreData.lastText = lastMsg[@"text"];
            [weakSelf.tableView reloadData];
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (IBAction)sendMsg:(id)sender {
    if(![self.msgInput.text isEqualToString:@""]) {
        __weak MessageViewController *weakSelf = self;
        if(!self.conversationCoreData) {
            self.conversationCoreData = (ConversationCoreData *) [[CoreDataManager shared] getConvoFromCoreData:self.user.objectId];
            if(self.conversationCoreData) {
                self.convo = [PFObject objectWithoutDataWithClassName:@"Convos" objectId:self.conversationCoreData.objectId];
            }
        }
        
        if (!self.convo) {
            PFObject *convo = [PFObject objectWithClassName:@"Convos"];
            convo[@"sender"] = [PFUser currentUser];
            convo[@"receiver"] = weakSelf.receiver;
            convo[@"lastText"] = self.msgInput.text;
            
            [convo saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (succeeded) {
                    [[CoreDataManager shared] saveConversationToCoreDataWithObjectId:convo.objectId withDate:convo.updatedAt withSender:weakSelf.user withLastText:convo[@"lastText"] withManagedObjectContext:weakSelf.context];
                    [weakSelf saveContext];
                    weakSelf.convo = convo;
                } else {
                    NSLog(@"%@", error.localizedDescription);
                }
            }];
        } else {
            self.convo[@"lastText"] = self.msgInput.text;
            [self.convo saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                if (!succeeded) {
                    NSLog(@"Problem updating convos class: %@", error.localizedDescription);
                }
            }];
        }
        
        PFObject *message = [PFObject objectWithClassName:@"Messages"];
        message[@"sender"] = [PFUser currentUser];
        message[@"receiver"] = self.receiver;
        message[@"text"] = self.msgInput.text;
        weakSelf.conversationCoreData.updatedAt = [NSDate date];
        
        [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
            if (succeeded) {
                weakSelf.conversationCoreData.lastText = self.msgInput.text;
                [weakSelf saveContext];
                weakSelf.msgInput.text = @"";
            } else {
                NSLog(@"Problem saving message: %@", error.localizedDescription);
            }
        }];
    }
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

- (void)saveContext {
    NSError *error = nil;
    if ([self.context hasChanges] && ![self.context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
