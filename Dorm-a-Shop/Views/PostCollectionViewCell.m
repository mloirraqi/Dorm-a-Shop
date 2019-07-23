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

- (void)setPost:(Post *)post {
    _post = post;
    [[PostManager shared] getCurrentUserWatchStatusForPost:post withCompletion:^(Post * _Nonnull post, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
        }
    }];
    
    [self.itemImage setImage:[UIImage imageNamed:@"item_placeholder"]];
    PFFileObject *imageFile = self.post.image;
    
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:imageData];
            [self.itemImage setImage:image];
        }
    }];
}

@end
