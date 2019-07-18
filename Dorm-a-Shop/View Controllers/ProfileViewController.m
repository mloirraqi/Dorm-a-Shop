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
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *activeCount;
@property (weak, nonatomic) IBOutlet UILabel *soldCount;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if(!self.user) {
        self.user = PFUser.currentUser;
    }
    self.username.text = self.user.username;
    self.navigationItem.title = [@"@" stringByAppendingString:self.user.username];
    self.profilePic.layer.cornerRadius = 40;
    self.profilePic.layer.masksToBounds = YES;
    PFFileObject *imageFile = self.user[@"ProfilePic"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:imageData];
            [self.profilePic setImage:image];
        }
    }];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.selectedSeg = 0;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*) self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    CGFloat posterPerLine = 2;
    CGFloat itemWidth = (self.collectionView.frame.size.width - layout.minimumInteritemSpacing * (posterPerLine - 1)) / posterPerLine;
    CGFloat itemHeight = itemWidth;
    layout.itemSize = CGSizeMake(itemWidth, itemHeight);
    [self fetchProfile];
}


- (void)fetchProfile {
    PFQuery *activeQuery = [PFQuery queryWithClassName:@"Post"];
    [activeQuery includeKey:@"author"];
    [activeQuery whereKey:@"author" equalTo:self.user];
    [activeQuery whereKey:@"sold" equalTo:[NSNumber numberWithBool:NO]];
    [activeQuery orderByDescending:@"createdAt"];
    
    PFQuery *soldQuery = [PFQuery queryWithClassName:@"Post"];
    [soldQuery includeKey:@"author"];
    [soldQuery whereKey:@"author" equalTo:self.user];
    [soldQuery whereKey:@"sold" equalTo:[NSNumber numberWithBool:YES]];
    [soldQuery orderByDescending:@"createdAt"];
    
    [activeQuery findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            self.activeItems = [NSMutableArray arrayWithArray:posts];
            self.activeCount.text = [NSString stringWithFormat:@"%lu", self.activeItems.count];
            [self.collectionView reloadData];
        } else {
            NSLog(@"😫😫😫 couldn't fetch active posts for some reason: %@", error.localizedDescription);
        }
    }];
    
    [soldQuery findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            self.soldItems = [NSMutableArray arrayWithArray:posts];
            self.soldCount.text = [NSString stringWithFormat:@"%lu", self.soldItems.count];
            [self.collectionView reloadData];
        } else {
            NSLog(@"😫😫😫 couldn't fetch sold posts for some reason: %@", error.localizedDescription);
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
