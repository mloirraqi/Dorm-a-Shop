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

@end

@implementation PostCollectionViewCell

- (void)setPost:(Post *)post {
//    [self setWatchedUser:[PFUser currentUser] Post:self.post];
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
