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
#import "CoreDataManager.h"

static const int MAX_BUFFER_SIZE = 2;

@interface DraggableViewBackground ()
@property (nonatomic, strong) NSMutableArray *cardArray;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, assign) NSInteger cardsLoadedIndex;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableArray *loadedCards;
@end

@implementation DraggableViewBackground

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
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
    self.userNameLabel.font = [UIFont systemFontOfSize:18];
    Card *card = self.cardArray.firstObject;
    self.userNameLabel.text = card.author.username;
    self.backgroundColor = [UIColor redColor];
    [self addSubview:self.userNameLabel];
    self.backgroundColor = [UIColor colorWithRed:168/255.f green:225/255.f blue:255/255.f alpha:1];
}

- (DraggableView *)createDraggableViewWithDataAtIndex:(NSInteger)index {
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGFloat cardWidth = screenSize.width - 80;
    CGFloat cardHeight = screenSize.height - (screenSize.height - self.frame.size.height) - 140;
    
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

    if([self.cardArray count] > 0) {
        NSInteger numLoadedCardsCap =(([self.cardArray count] > MAX_BUFFER_SIZE)?MAX_BUFFER_SIZE:[self.cardArray count]);
        
        for (int i = 0; i<[self.cardArray count]; i++) {
            DraggableView* newCard = [self createDraggableViewWithDataAtIndex:i];
            [self.allCards addObject:newCard];
            
            if (i<numLoadedCardsCap) {
                [self.loadedCards addObject:newCard];
            }
        }
    
        for (int i = 0; i<[self.loadedCards count]; i++) {
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
    [[PFUser currentUser] addUniqueObjectsFromArray:@[card.author.objectId] forKey:@"accepted"];
    [[PFUser currentUser] saveEventually];
    [self checkMatchwithUser:card.author];
    
}

- (void)checkMatchwithUser:(PFUser *)acceptedUser {
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"objectId" equalTo:acceptedUser.objectId];
    
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray<PFUser *> * _Nullable users, NSError * _Nullable error) {
        if (users) {
            if (users.count != 0) {
                PFUser *currentUser = [PFUser currentUser];
                PFUser *user = [users firstObject];
                NSArray *acceptedUserList = user[@"accepted"];
                if ([acceptedUserList containsObject:currentUser.objectId]) {
                    [self showAlertView:[NSString stringWithFormat:@"Congratulations! You matched with %@",user.username]];
                } else {
                    NSLog(@"😫😫😫 users are not matched yet");
                }
            } else {
                NSLog(@"😫😫😫 No such User Found");
            }
        } else {
            NSLog(@"😫😫😫 Error getting User to CheckMatch: %@", error.localizedDescription);
        }
    }];
}

- (void)userRejected:(Card *)card {
    [[PFUser currentUser] addUniqueObjectsFromArray:@[card.author.objectId] forKey:@"rejected"];
    [[PFUser currentUser] saveEventually];
    
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
    
    for (PFUser *user in userArray) {
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
    
    [self loadCards];
    [self setupView];
}

-(void)showAlertView:(NSString*)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Dorm-a-Shop" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
