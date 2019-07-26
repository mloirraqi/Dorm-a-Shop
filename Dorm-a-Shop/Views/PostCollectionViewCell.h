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

@property (nonatomic, strong) Post *post;
@property (weak, nonatomic) IBOutlet UIImageView *itemImage;

@end

NS_ASSUME_NONNULL_END
