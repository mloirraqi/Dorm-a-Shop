//
//  DraggableViewBackground.m
//  RKSwipeCards
//
//  Created by Richard Kim on 8/23/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//

#import "DraggableViewBackground.h"
#import "ParseDatabaseManager.h"
#import "Post.h"
#import <Parse/Parse.h>
#import "Card.h"
#import "SwipePopupVC.h"
#import "CoreDataManager.h"
#import "AppDelegate.h"

static const int MAX_BUFFER_SIZE = 2;

@interface DraggableViewBackground ()
@property (nonatomic, strong) NSMutableArray *cardArray;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, assign) NSInteger cardsLoadedIndex;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableArray *loadedCards;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation DraggableViewBackground

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        self.context = appDelegate.persistentContainer.viewContext;
        
        self.loadedCards = [[NSMutableArray alloc] init];
        self.allCards = [[NSMutableArray alloc] init];
        self.cardArray = [[NSMutableArray alloc]init];
        self.cardsLoadedIndex = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshContent:) name:@"DidPullActivePosts" object:nil];
        [self setupCards];
    }
    return self;
}

- (void)refreshContent:(NSNotification *)notification {
    self.loadedCards = [[NSMutableArray alloc] init];
    self.allCards = [[NSMutableArray alloc] init];
    self.cardArray = [[NSMutableArray alloc]init];
    self.cardsLoadedIndex = 0;
    self.currentIndex = 0;
    [self setupCards];
}

- (void)setupView {
    self.currentIndex = 0;
    
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGRect frame = CGRectMake(0, 24, screenSize.width, 24);
    self.userNameLabel = [[UILabel alloc] initWithFrame: frame];
    [self addSubview:self.userNameLabel];
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    self.userNameLabel.font = [UIFont boldSystemFontOfSize:24];
    Card *card = self.cardArray.firstObject;
    self.userNameLabel.text = card.author.username;
//    self.navigationItem.title = card.author.username;
    self.backgroundColor = [UIColor blueColor];
    self.backgroundColor = [UIColor colorWithRed:.0f/255.0f green:228.0f/255.0f blue:232.0f/255 alpha:1.0f];
}

- (DraggableView *)createDraggableViewWithDataAtIndex:(NSInteger)index {
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGFloat cardWidth = screenSize.width - 20;
    CGFloat cardHeight = screenSize.height - (screenSize.height - self.frame.size.height) - 120;
    
    CGRect frame = CGRectMake(((screenSize.width) - cardWidth)/2, ((screenSize.height - (screenSize.height - self.frame.size.height)) - cardHeight)/2, cardWidth, cardHeight);
    
    DraggableView *draggableView = [[DraggableView alloc]initWithFrame:frame];
    draggableView.card = self.cardArray[index];
    draggableView.delegate = self;
    
    return draggableView;
}

- (void)loadCards {
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    if ([self.cardArray count] > 0) {
        NSInteger numLoadedCardsCap = (([self.cardArray count] > MAX_BUFFER_SIZE)?MAX_BUFFER_SIZE:[self.cardArray count]);
        
        for (int i = 0; i < [self.cardArray count]; i++) {
            DraggableView* newCard = [self createDraggableViewWithDataAtIndex:i];
            [self.allCards addObject:newCard];
            
            if (i<numLoadedCardsCap) {
                [self.loadedCards addObject:newCard];
            }
        }
        
        for (int i = 0; i < [self.loadedCards count]; i++) {
            if (i>0) {
                [self insertSubview:[self.loadedCards objectAtIndex:i] belowSubview:[self.loadedCards objectAtIndex:i-1]];
            } else {
                [self addSubview:[self.loadedCards objectAtIndex:i]];
            }
            self.cardsLoadedIndex++;
        }
    }
}

- (void)cardSwipedLeft:(UIView *)card {
    [self.loadedCards removeObjectAtIndex:0];
    if (self.cardsLoadedIndex < [self.allCards count]) {
        [self.loadedCards addObject:[self.allCards objectAtIndex:self.cardsLoadedIndex]];
        self.cardsLoadedIndex++;
        [self insertSubview:[self.loadedCards objectAtIndex:(MAX_BUFFER_SIZE-1)] belowSubview:[self.loadedCards objectAtIndex:(MAX_BUFFER_SIZE-2)]];
    }
    
    Card *swipedCard = self.cardArray[self.currentIndex];
    [self userRejected:swipedCard];
    [self updateUsernameLabel];
}

- (void)cardSwipedRight:(UIView *)card {
    [self.loadedCards removeObjectAtIndex:0];
    if (self.cardsLoadedIndex < [self.allCards count]) {
        [self.loadedCards addObject:[self.allCards objectAtIndex:self.cardsLoadedIndex]];
        self.cardsLoadedIndex++;
        [self insertSubview:[self.loadedCards objectAtIndex:(MAX_BUFFER_SIZE-1)] belowSubview:[self.loadedCards objectAtIndex:(MAX_BUFFER_SIZE-2)]];
    }
    
    Card *swipedCard = self.cardArray[self.currentIndex];
    [self userAccepted:swipedCard];
    [self updateUsernameLabel];
}

- (void)userAccepted:(Card *)card {
    __weak DraggableViewBackground *weakSelf = self;
    PFQuery *matchQuery = [PFQuery queryWithClassName:@"SwipeRecord"];
    [matchQuery whereKey:@"initiator" equalTo:(PFUser *) [PFObject objectWithoutDataWithClassName:@"_User" objectId:card.author.objectId]];
    [matchQuery whereKey:@"recipient" equalTo:[PFUser currentUser]];
    
    [matchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable matchArray, NSError * _Nullable error) {
        if(!error) {
            if(matchArray.count > 0) {
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
        if(!error) {
            if(matchArray.count > 0) {
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
        } else {
            NSLog(@"Problem querying swipeRecord: %@", error.localizedDescription);
        }
    }];

}

- (void)updateUsernameLabel {
    if (self.cardArray.count-1 > self.currentIndex) {
        self.currentIndex++;
        Card *card = self.cardArray[self.currentIndex];
        self.userNameLabel.text = card.author.username;
    } else {
        self.userNameLabel.text = @"";
    }
}

-(void)setupCards {
    self.cardArray = [[NSMutableArray alloc]init];
    NSMutableArray *activePosts = [[CoreDataManager shared] getActivePostsFromCoreData];
    NSMutableArray *userNameArray = [[NSMutableArray alloc] init];
    NSMutableArray *userArray = [[NSMutableArray alloc] init];
    for (Post *post in activePosts) {
        if (post.author != nil && post.author.username != nil) {
            if (![userNameArray containsObject:post.author.username]) {
                if (![post.author.objectId isEqualToString:[PFUser currentUser].objectId]) {
                    [userNameArray addObject:post.author.username];
                    [userArray addObject:post.author];
                }
            }
        }
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(userId = %@)", [PFUser currentUser].objectId]; //my userId will exist only to SwipeRecords I added.
    PFQuery *query = [PFQuery queryWithClassName:@"SwipeRecord" predicate:predicate];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable swipeRecords, NSError * _Nullable error) {
        
        NSMutableSet* matchedUsersId = [[NSMutableSet alloc] init];
        
        if (swipeRecords) {
            if (swipeRecords.count != 0) { //We will have > 0 count if accepted user and userid matches where clause.
                NSLog(@"😍 Found %lu records already swiped", (unsigned long)swipeRecords.count);
                
                for (PFObject *record in swipeRecords) {
                    if (record[@"accepted"] != nil)
                        [matchedUsersId addObject:record[@"accepted"]];
                    if (record[@"rejected"] != nil)
                        [matchedUsersId addObject:record[@"rejected"]];
                }
                
                NSLog(@"%@", matchedUsersId);
                
            } else {
                NSLog(@"😫😫😫 No such User Found");
            }
        } else {
            NSLog(@"😫😫😫 Error getting User to CheckMatch: %@", error.localizedDescription);
        }
        
        for (PFUser *user in userArray) {
            
            if (![matchedUsersId containsObject:user.objectId]) {
                
                NSMutableArray *userPosts = [[NSMutableArray alloc] init];
                Card *card = [[Card alloc]init];
                card.author = user;
                card.posts = userPosts;
                for (Post *post in activePosts) {
                    if ([post.author.objectId isEqualToString:user.objectId]) {
                        [userPosts addObject:post];
                    }
                }
                [self.cardArray addObject:card];
            }
        }
    
    [self loadCards];
    [self setupView];
    }];
}

- (void)showAlertView:(NSString*)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dorm-a-Shop" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
