//
//  MatchedViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 8/8/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "MatchedViewController.h"
#import "UserCollectionCell.h"
#import "UserCoreData+CoreDataClass.h"
#import "User.h"
#import "ParseDatabaseManager.h"
#import "CoreDataManager.h"

@import Parse;

@interface MatchedViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *matchedUsersArray;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIView *noMatchesView;

@end

@implementation MatchedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.navigationItem.title = @"Matched Users";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchMatchedFromCoreData) forControlEvents:UIControlEventValueChanged];
    [self.collectionView insertSubview:self.refreshControl atIndex:0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"DidMatchWithUserNotification" object:nil];
    
    [self fetchMatchedFromCoreData];
}

- (void)receiveNotification:(NSNotification *)notification {
    if ([[notification name] isEqualToString:@"DidMatchWithUserNotification"]) {
        UserCoreData *matchedUser = [[notification userInfo] objectForKey:@"matchedUser"];
        [self.matchedUsersArray addObject:matchedUser];
        self.noMatchesView.hidden = YES;
        [self.collectionView reloadData];
    }
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UserCollectionCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"UserCollectionCell" forIndexPath:indexPath];
    UserCoreData *user = self.matchedUsersArray[indexPath.item];
    cell.user = user;
    [cell setUser];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.matchedUsersArray.count;
}

- (void)fetchMatchedFromCoreData {
    self.matchedUsersArray = [[CoreDataManager shared] getAllMatchedUsersFromCoreData];
    [self.collectionView reloadData];
    [self.refreshControl endRefreshing];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (collectionView.frame.size.width/2) - 4; //(4 is interitempadding)
    return CGSizeMake(width, width + 70); //70 is size of two labels
}

@end
