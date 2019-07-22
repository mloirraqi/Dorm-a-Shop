//
//  PostCollectionViewCell.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "PostCollectionViewCell.h"
#import "PostManager.h"

@interface PostCollectionViewCell()

@property (nonatomic) BOOL isInitialReload;

@end

@implementation PostCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.isInitialReload = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isInitialReload = YES;
}

- (void)setPost {
    if (self.isInitialReload) {
        [self setUIWatchedForCurrentUserForPost:self.post];
    }
    
    [self.itemImage setImage:[UIImage imageNamed:@"item_placeholder"]];
    PFFileObject *imageFile = self.post.image;
    
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:imageData];
            [self.itemImage setImage:image];
        }
    }];
}

- (void)setUIWatchedForCurrentUserForPost:(Post *)post{
    /*PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
    [watchQuery orderByDescending:@"createdAt"];
    [watchQuery whereKey:@"post" equalTo:post];
    
    __weak PostCollectionViewCell *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable postWatches, NSError * _Nullable error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
        } else {
            self.isInitialReload = NO;
            weakSelf.post.watchCount = postWatches.count;
            if (weakSelf.post.watchCount > 0) {
                bool watched = NO;
                for (PFObject *watch in postWatches) {
                    if ([((PFObject *)watch[@"user"]).objectId isEqualToString:user.objectId]) {
                        weakSelf.post.watch = watch;
                        watched = YES;
                        break;
                    }
                }
                if (!watched) {
                    weakSelf.post.watch = nil;
                }
            } else {
                weakSelf.post.watch = nil;
            }
        }
    }];*/
    
    if (((PostManager *)[PostManager shared]).watchedPostsArray == nil) {
        [[PostManager shared] getWatchedPostsForCurrentUserWithCompletion:^(NSMutableArray * _Nonnull watchedPostsArray, NSError * _Nonnull error) {
            if (error) {
                NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
            }
        }];
    }
}

@end
