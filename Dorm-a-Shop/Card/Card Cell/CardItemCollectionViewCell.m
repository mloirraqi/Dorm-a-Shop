//
//  CardItemCollectionViewCell.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 07/24/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "CardItemCollectionViewCell.h"
@import Parse;

@interface CardItemCollectionViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *postImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@end

@implementation CardItemCollectionViewCell

//@synthesize _post = post;

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setPost:(PostCoreData *)post {
	_post = post;
    
	[self.postImageView setImage:[UIImage imageNamed:@"item_placeholder"]];
    self.postImageView.image = [UIImage imageWithData:self.post.image];
	
	self.titleLabel.text = post.title;
	self.priceLabel.text = [NSString stringWithFormat:@"$%f", post.price];
}

@end
