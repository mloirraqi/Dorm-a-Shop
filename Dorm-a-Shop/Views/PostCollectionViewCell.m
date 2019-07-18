//
//  PostCollectionViewCell.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "PostCollectionViewCell.h"

@implementation PostCollectionViewCell



- (void)setPic:(Post *)post {
    [self setWatchedUser:[PFUser currentUser] Post:post];
    
    PFFileObject *imageFile = post.image;
    
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:imageData];
            [self.itemImage setImage:image];
        }
    }];
}

- (void)setWatchedUser:(PFUser *)user Post:(Post *)post{
    PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
    [watchQuery orderByDescending:@"createdAt"];
    [watchQuery whereKey:@"postID" equalTo:post.objectId];
    
    __weak PostCollectionViewCell *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable postWatches, NSError * _Nullable error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
        } else {
            weakSelf.watchCount = postWatches.count;
            if (weakSelf.watchCount > 0) {
                bool watched = NO;
                for (PFObject *watch in postWatches) {
                    if ([watch[@"userID"] isEqualToString:user.objectId]) {
                        weakSelf.watch = watch;
                        watched = YES;
                        break;
                    }
                }
                if (!watched) {
                    weakSelf.watch = nil;
                }
            } else {
                weakSelf.watch = nil;
            }
        }
    }];
}

@end
