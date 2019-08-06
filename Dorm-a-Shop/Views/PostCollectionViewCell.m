//
//  PostCollectionViewCell.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "PostCollectionViewCell.h"
#import "ParseDatabaseManager.h"

@implementation PostCollectionViewCell

- (void)setPost:(PostCoreData *)post {
    _post = post;
    self.itemTitle.text = post.title;
    [self.itemImage setImage:[UIImage imageNamed:@"item_placeholder"]];
    NSData *imageData = post.image;
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        [self.itemImage setImage:image];
    }
}

@end
