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
    
    if (self.post.image) {
        self.postImageView.image = [UIImage imageWithData:self.post.image];
    }
	
	self.titleLabel.text = post.title;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:2];
    [formatter setRoundingMode: NSNumberFormatterRoundUp];
    
    NSString *priceString = [formatter stringFromNumber:[NSNumber numberWithFloat:post.price]];
    
	self.priceLabel.text = [NSString stringWithFormat:@"$%@", priceString];
}

@end
