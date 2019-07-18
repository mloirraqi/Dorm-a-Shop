//
//  PostCollectionViewCell.h
//  Dorm-a-Shop
//
//  Created by addisonz on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

NS_ASSUME_NONNULL_BEGIN

@interface PostCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *itemImage;
- (void)setPic:(Post *) post;

@property (nonatomic, strong) PFObject *watch;
@property (nonatomic, strong) Post *post;
@property (nonatomic) NSUInteger watchCount;

@end

NS_ASSUME_NONNULL_END
