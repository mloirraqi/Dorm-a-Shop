//
//  PostTableViewCell.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface PostTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet PFImageView *postPFImageView;
@property (weak, nonatomic) IBOutlet UIButton *watchButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) PFObject *watch;

@end

NS_ASSUME_NONNULL_END
