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
@import Parse;

@interface MatchedViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *matchedUsersArray;
@property (weak, nonatomic) IBOutlet UIView *noMatchesView;

@end

@implementation MatchedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self fetchMatchedFromParse];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UserCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"UserCollectionCell" forIndexPath:indexPath];
        
    User* userCoreData = (User*)self.matchedUsersArray[indexPath.item];
    
    PFFileObject *image = userCoreData.ProfilePic;
    
    [image getDataInBackgroundWithBlock:^(NSData *_Nullable data, NSError * _Nullable error) {
        UIImage *originalImage = [UIImage imageWithData:data];
        [cell.profilePic setImage:originalImage];
    }];
    
    cell.username.text = userCoreData.username;
    cell.locationLabel.text = userCoreData.address;
    
    cell.username.textColor = [UIColor blackColor];
    cell.locationLabel.textColor = [UIColor blackColor];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.matchedUsersArray.count;
}

- (void)fetchMatchedFromParse {
    __weak MatchedViewController *weakSelf = self;
    
    NSString* userId = [PFUser currentUser].objectId;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(userId = %@ OR accepted = %@) AND matched = 1", userId, userId];
    PFQuery *query = [PFQuery queryWithClassName:@"SwipeRecord" predicate:predicate];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable swipeRecords, NSError * _Nullable error) {
        if (swipeRecords) {
            if (swipeRecords.count != 0) { //We will have > 0 count if accepted user and userid matches where clause.
                NSLog(@"😍 Found %lu records", (unsigned long)swipeRecords.count);
                NSMutableArray* usersToQuery = [[NSMutableArray alloc] init];
                for (PFObject* record in swipeRecords) {
                    NSString* objectId1 = record[@"accepted"];
                    NSString* objectId2 = record[@"userId"];
                    
                    NSString* objectId = [userId isEqualToString:objectId1] ? objectId2 : objectId1;
                    
                    [usersToQuery addObject:objectId];
                }
                
                [[ParseDatabaseManager shared] queryAllUsers:usersToQuery WithCompletion:^(NSArray* users, NSError* error) {
                    weakSelf.matchedUsersArray = [users mutableCopy];
                    
                    if (weakSelf.matchedUsersArray.count == 0) {
                        [self.noMatchesView setHidden:NO];
                    } else {
                        [self.noMatchesView setHidden:YES];
                        [weakSelf.collectionView reloadData];
                    }
                }];
            } else {
                NSLog(@"😫😫😫 No such User Found");
            }
        } else {
            NSLog(@"😫😫😫 Error getting User to CheckMatch: %@", error.localizedDescription);
            [weakSelf.matchedUsersArray removeAllObjects];
            [self.noMatchesView setHidden:NO];
        }
    }];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (collectionView.frame.size.width/3) - 4; //(4 is interitempadding)
    return CGSizeMake(width, width + 70); //70 is size of two labels

}



@end
