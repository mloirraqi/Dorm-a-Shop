//
//  DraggableViewBackground.m
//  RKSwipeCards
//
//  Created by Richard Kim on 8/23/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//
// Modified 2019 by Ilana Shapiro, Addison Zhang, Mohamed Loirraqi

#import "DraggableViewBackground.h"
#import "ParseDatabaseManager.h"
#import "Post.h"
#import <Parse/Parse.h>
#import "Card.h"
#import "SwipePopupVC.h"
#import "CoreDataManager.h"
#import "AppDelegate.h"
#import "NSNotificationCenter+MainThread.h"

@interface DraggableViewBackground ()

@property (nonatomic, strong) NSMutableArray *usersArray;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, assign) NSInteger usersLoadedIndex;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableArray *loadedUsers;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) Card *currentCard;
@property (nonatomic, strong) Card *previousCard;

@end

@implementation DraggableViewBackground

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        self.context = appDelegate.persistentContainer.viewContext;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshContent:) name:@"DidPullActivePosts" object:nil];
        [self setupCards];
    }
    return self;
}

- (void)refreshContent:(NSNotification *)notification {
    [self setupCards];
}

- (void)setupView {
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGRect frame = CGRectMake(0, 24, screenSize.width, 24);
    self.userNameLabel = [[UILabel alloc] initWithFrame: frame];
    [self addSubview:self.userNameLabel];
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    self.userNameLabel.font = [UIFont boldSystemFontOfSize:24];
    self.userNameLabel.text = self.currentCard.author.username;
}

- (DraggableView *)createDraggableViewWithDataForCard:(Card *)card {
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGFloat cardWidth = screenSize.width - 20;
    CGFloat cardHeight = screenSize.height - (screenSize.height - self.frame.size.height) - 120;
    
    CGRect frame = CGRectMake(((screenSize.width) - cardWidth)/2, ((screenSize.height - (screenSize.height - self.frame.size.height)) - cardHeight)/2, cardWidth, cardHeight);
    
    DraggableView *draggableView = [[DraggableView alloc]initWithFrame:frame];
    draggableView.card = card;
    draggableView.delegate = self;
    
    return draggableView;
}

- (void)loadCards {
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }

    DraggableView *newCardView = [self createDraggableViewWithDataForCard:self.currentCard];
    DraggableView *previousCardView = [self createDraggableViewWithDataForCard:self.previousCard];
    if ([self.usersArray count] > 0 && self.previousCard) {
        [self insertSubview:newCardView belowSubview:previousCardView];
    } else if ([self.usersArray count] > 0) {
        [self addSubview:newCardView];
    }
}

- (void)cardSwipedLeft:(UIView *)card {
    Card *swipedCard = self.currentCard;
    [self.usersArray removeObjectAtIndex:0];
    NSLog(@"self.usersArray: %@", self.usersArray);
    if (self.usersArray.count > 0) {
        self.previousCard = self.currentCard;
        NSMutableArray *postsArray = [[CoreDataManager shared] getActivePostsFromCoreDataForUser:self.usersArray.firstObject];
        NSLog(@"%@", self.usersArray.firstObject);
        self.currentCard = [[Card alloc] initWithUser:self.usersArray.firstObject postsArray:postsArray];
        DraggableView *newCardView = [self createDraggableViewWithDataForCard:self.currentCard];
        DraggableView *previousCardView = [self createDraggableViewWithDataForCard:self.previousCard];
        [self insertSubview:newCardView belowSubview:previousCardView];
    }
    
    [self userRejected:swipedCard];
    [self updateUsernameLabel];
}

- (void)cardSwipedRight:(UIView *)card {
    Card *swipedCard = self.currentCard;
    [self.usersArray removeObjectAtIndex:0];
    NSLog(@"self.usersArray: %@", self.usersArray);
    
    if (self.usersArray.count > 0) {
        self.previousCard = self.currentCard;
        NSMutableArray *postsArray = [[CoreDataManager shared] getActivePostsFromCoreDataForUser:self.usersArray.firstObject];
        self.currentCard = [[Card alloc] initWithUser:self.usersArray.firstObject postsArray:postsArray];
        DraggableView *newCardView = [self createDraggableViewWithDataForCard:self.currentCard];
        DraggableView *previousCardView = [self createDraggableViewWithDataForCard:self.previousCard];
        [self insertSubview:newCardView belowSubview:previousCardView];
    }
    
    [self userAccepted:swipedCard];
    [self updateUsernameLabel];
}

- (void)userAccepted:(Card *)card {
    __weak DraggableViewBackground *weakSelf = self;
    PFQuery *matchQuery = [PFQuery queryWithClassName:@"SwipeRecord"];
    [matchQuery whereKey:@"initiator" equalTo:(PFUser *) [PFObject objectWithoutDataWithClassName:@"_User" objectId:card.author.objectId]];
    [matchQuery whereKey:@"recipient" equalTo:[PFUser currentUser]];
    
    [matchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable matchArray, NSError * _Nullable error) {
        if (!error) {
            if (matchArray.count > 0) {
                PFObject *swipeRecord = matchArray[0];
                swipeRecord[@"match"] = @2;
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                SwipePopupVC* controller = [storyboard instantiateViewControllerWithIdentifier:@"SwipePopupVC"];
                
                UserCoreData* user = (UserCoreData *)[[CoreDataManager shared] getCoreDataEntityWithName:@"UserCoreData" withObjectId:card.author.objectId withContext:weakSelf.context];
                controller.userCoreData = user;
                
                UIViewController *vc1 = [UIApplication sharedApplication].keyWindow.rootViewController;
                
                controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                [controller setModalTransitionStyle: UIModalTransitionStyleCrossDissolve];
                
                [vc1 presentViewController:controller animated:YES completion:nil];
                [swipeRecord saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if(succeeded) {
                        NSLog(@"The swipeRecord was updated!");
                    } else {
                        NSLog(@"Problem saving swipeRecord: %@", error.localizedDescription);
                    }
                }];
                
                NSLog(@"card.author: %@", card.author);
                card.author.matchedToCurrentUser = YES;
                
                NSDictionary *matchedInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:card.author, @"matchedUser", nil];
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"DidMatchWithUserNotification" object:weakSelf userInfo:matchedInfoDict];
            } else {
                PFObject *swipeRecord = [PFObject objectWithClassName:@"SwipeRecord"];
                swipeRecord[@"initiator"] = [PFUser currentUser];
                swipeRecord[@"recipient"] = (PFUser *) [PFObject objectWithoutDataWithClassName:@"_User" objectId:card.author.objectId];
                swipeRecord[@"match"] = @1;
                [swipeRecord saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                    if (succeeded) {
                        NSLog(@"The swipeRecord was saved!");
                    } else {
                        NSLog(@"Problem saving swipeRecord: %@", error.localizedDescription);
                    }
                }];
            }
            
            card.author.available = NO;
            [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
                return YES;
            } withName:card.author.objectId];
        } else {
            NSLog(@"Problem querying swipeRecord: %@", error.localizedDescription);
        }
    }];
}

- (void)userRejected:(Card *)card {
    PFQuery *matchQuery = [PFQuery queryWithClassName:@"SwipeRecord"];
    [matchQuery whereKey:@"initiator" equalTo:(PFUser *) [PFObject objectWithoutDataWithClassName:@"_User" objectId:card.author.objectId]];
    [matchQuery whereKey:@"recipient" equalTo:[PFUser currentUser]];
    
    [matchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable matchArray, NSError * _Nullable error) {
        if (!error) {
            if (matchArray.count > 0) {
                PFObject *swipeRecord = matchArray[0];
                swipeRecord[@"match"] = @0;
                [swipeRecord saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    if(succeeded) {
                        NSLog(@"The swipeRecord was updated!");
                    } else {
                        NSLog(@"Problem saving swipeRecord: %@", error.localizedDescription);
                    }
                }];
            } else {
                PFObject *swipeRecord = [PFObject objectWithClassName:@"SwipeRecord"];
                swipeRecord[@"initiator"] = [PFUser currentUser];
                swipeRecord[@"recipient"] = (PFUser *) [PFObject objectWithoutDataWithClassName:@"_User" objectId:card.author.objectId];
                swipeRecord[@"match"] = @0;
                [swipeRecord saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                    if (succeeded) {
                        NSLog(@"The swipeRecord was saved!");
                    } else {
                        NSLog(@"Problem saving swipeRecord: %@", error.localizedDescription);
                    }
                }];
            }
            
            card.author.available = NO;
            [[CoreDataManager shared] enqueueCoreDataBlock:^BOOL(NSManagedObjectContext * _Nonnull context) {
                return YES;
            } withName:card.author.objectId];
        } else {
            NSLog(@"Problem querying swipeRecord: %@", error.localizedDescription);
        }
    }];

}

- (void)updateUsernameLabel {
    if (self.usersArray.count > 0) {
        self.userNameLabel.text = self.currentCard.author.username;
    } else {
        self.userNameLabel.text = @"";
    }
}

-(void)setupCards {
    self.usersArray = [[CoreDataManager shared] getAllAvailabeUsersFromCoreData];
    NSMutableArray *postsArray = [[CoreDataManager shared] getActivePostsFromCoreDataForUser:self.usersArray.firstObject];
    NSLog(@"self.usersArray: %@", self.usersArray);
    self.currentCard = [[Card alloc] initWithUser:self.usersArray.firstObject postsArray:postsArray];
    [self loadCards];
    [self setupView];
}

@end
