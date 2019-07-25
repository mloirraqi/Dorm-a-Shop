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
@property (weak, nonatomic) IBOutlet PFImageView *postPFImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@end

@implementation CardItemCollectionViewCell

//@synthesize _post = post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}


-(void)setPost:(Post *)post {
	_post = post;
	[self.postPFImageView setImage:[UIImage imageNamed:@"item_placeholder"]];
	self.postPFImageView.file = post[@"image"];
	[self.postPFImageView loadInBackground];
	
	self.titleLabel.text = post.title;
	self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}


@end
