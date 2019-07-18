//
//  ProfileViewController.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "ProfileViewController.h"
#import "PostCollectionViewCell.h"
#import "Post.h"

@import Parse;

@interface ProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *activeItems;
@property (nonatomic, strong) NSArray *soldItems;
@property (nonatomic, strong) NSNumber *selectedSeg;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.selectedSeg = 0;

    
//    if(!self.user) {
//        self.user = PFUser.currentUser;
//    }
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    CGFloat posterPerLine = 2;
    CGFloat itemWidth = (self.collectionView.frame.size.width - layout.minimumInteritemSpacing * (posterPerLine - 1)) / posterPerLine;
    CGFloat itemHeight = itemWidth;
    layout.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    [self fetchProfile];

    
}

// query for all the posts uploaded by this user
- (void)fetchProfile {
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
//    [query includeKey:@"author"];
//    [query whereKey:@"author" equalTo:self.user];
    [query orderByDescending:@"createdAt"];
    
    // fetch all posts by current user asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            NSLog(@"😎😎😎 Successfully fetched posts from user");
            self.activeItems = [NSMutableArray arrayWithArray:posts];
            self.soldItems = [NSMutableArray arrayWithArray:posts];
//            self.postLabel.text = [NSString stringWithFormat:@"%lu", self.posts.count];;
            [self.collectionView reloadData];
            
        } else {
            NSLog(@"😫😫😫 couldn't fetch post for some reason: %@", error.localizedDescription);
        }
    }];
}

- (IBAction)changedSeg:(id)sender {
    [self.collectionView reloadData];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if([self.segControl selectedSegmentIndex] == 0) {
        PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"active" forIndexPath:indexPath];
        cell.itemImage.image = nil;
        Post *post = self.activeItems[indexPath.item];
        [cell setPic:post];
        return cell;
    } else {
        PostCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"sold" forIndexPath:indexPath];
        Post *post = self.soldItems[indexPath.item];
        cell.itemImage.image = nil;
        [cell setPic:post];
        return cell;
    }
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if([self.segControl selectedSegmentIndex] == 0) {
        return self.activeItems.count;
    } else {
        return self.soldItems.count;
    }
}


@end
