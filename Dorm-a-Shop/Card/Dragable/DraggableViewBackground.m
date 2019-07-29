//
//  DraggableViewBackground.m
//  RKSwipeCards
//
//  Created by Richard Kim on 8/23/14.
//  Copyright (c) 2014 Richard Kim. All rights reserved.
//

#import "DraggableViewBackground.h"
#import "PostManager.h"
#import "Post.h"
#import <Parse/Parse.h>
#import "Card.h"

static const int MAX_BUFFER_SIZE = 2;

@interface DraggableViewBackground ()
@property (nonatomic, strong) NSMutableArray *cardArray;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, assign) NSInteger cardsLoadedIndex;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSMutableArray *loadedCards;
@end

@implementation DraggableViewBackground

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.loadedCards = [[NSMutableArray alloc] init];
        self.allCards = [[NSMutableArray alloc] init];
        self.cardsLoadedIndex = 0;
        [self setupCards];
    }
    return self;
}

-(void)setupView {
    self.currentIndex = 0;
    
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGRect frame = CGRectMake(0, 24, screenSize.width, 24);
    
    self.userNameLabel = [[UILabel alloc] initWithFrame: frame];
    self.userNameLabel.textAlignment = NSTextAlignmentCenter;
    self.userNameLabel.font = [UIFont systemFontOfSize:18];
    Card *card = self.cardArray.firstObject;
    self.userNameLabel.text = card.author.username;
    self.backgroundColor = [UIColor redColor];
    [self addSubview:self.userNameLabel];
    self.backgroundColor = [UIColor colorWithRed:168/255.f green:225/255.f blue:255/255.f alpha:1];
}

-(DraggableView *)createDraggableViewWithDataAtIndex:(NSInteger)index {
    CGSize screenSize = UIScreen.mainScreen.bounds.size;
    CGFloat cardWidth = screenSize.width - 80;
    CGFloat cardHeight = screenSize.height - (screenSize.height - self.frame.size.height) - 140;
    
    CGRect frame = CGRectMake(((screenSize.width) - cardWidth)/2, ((screenSize.height - (screenSize.height - self.frame.size.height)) - cardHeight)/2, cardWidth, cardHeight);
    
    DraggableView *draggableView = [[DraggableView alloc]initWithFrame:frame];
    draggableView.card = self.cardArray[index];
    draggableView.delegate = self;
    
    return draggableView;
}

-(void)loadCards {

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

-(void)cardSwipedLeft:(UIView *)card {
    [self.loadedCards removeObjectAtIndex:0];
    if (self.cardsLoadedIndex < [self.allCards count]) {
        [self.loadedCards addObject:[self.allCards objectAtIndex:self.cardsLoadedIndex]];
        self.cardsLoadedIndex++;
        [self insertSubview:[self.loadedCards objectAtIndex:(MAX_BUFFER_SIZE-1)] belowSubview:[self.loadedCards objectAtIndex:(MAX_BUFFER_SIZE-2)]];
    }
    [self updateUsernameLabel];
}

-(void)cardSwipedRight:(UIView *)card {
    [self.loadedCards removeObjectAtIndex:0];
    if (self.cardsLoadedIndex < [self.allCards count]) {
        [self.loadedCards addObject:[self.allCards objectAtIndex:self.cardsLoadedIndex]];
        self.cardsLoadedIndex++;
        [self insertSubview:[self.loadedCards objectAtIndex:(MAX_BUFFER_SIZE-1)] belowSubview:[self.loadedCards objectAtIndex:(MAX_BUFFER_SIZE-2)]];
    }
    [self updateUsernameLabel];
}

-(void)updateUsernameLabel {
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
    NSMutableArray *activePosts = [[PostManager shared] getActivePostsFromCoreData];
    NSMutableArray *userNameArray = [[NSMutableArray alloc] init];
    NSMutableArray *userArray = [[NSMutableArray alloc] init];
    for (Post *post in activePosts) {
        if (post.author != nil) {
            if (![userNameArray containsObject:post.author.username]) {
                [userNameArray addObject:post.author.username];
                [userArray addObject:post.author];
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

@end
