//
//  ReviewTableViewCell.m
//
//
//  Created by ilanashapiro on 8/2/19.
//

#import "ReviewTableViewCell.h"
#import "UserCoreData+CoreDataClass.h"
#import "ReviewCoreData+CoreDataClass.h"
#import "NSDate+DateTools.h"
#import "UILabel+Boldify.h"

@interface ReviewTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *sellerLabel;
@property (weak, nonatomic) IBOutlet UILabel *reviewerLabel;
@property (weak, nonatomic) IBOutlet UILabel *reviewDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UILabel *reviewLabel;
@property (weak, nonatomic) IBOutlet UIImageView *sellerProfileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *reviewerProfileImageView;

@end

@implementation ReviewTableViewCell

- (void)setReview:(ReviewCoreData *)review {
    _review = review;
    
    self.reviewDateLabel.text = [NSString stringWithFormat:@"%@", [review.dateWritten shortTimeAgoSinceNow]];
    self.ratingLabel.text = [NSString stringWithFormat:@"%d/5", (int)review.rating];
    self.reviewerLabel.text = review.reviewer.username;
    self.sellerLabel.text = review.seller.username;
    self.reviewLabel.text = review.review;
    
    self.sellerProfileImageView.layer.cornerRadius = 15;
    self.sellerProfileImageView.layer.masksToBounds = YES;
    [self.sellerProfileImageView setImage:[UIImage imageWithData:review.seller.profilePic]];
    
    self.reviewerProfileImageView.layer.cornerRadius = 15;
    self.reviewerProfileImageView.layer.masksToBounds = YES;
    [self.reviewerProfileImageView setImage:[UIImage imageWithData:review.reviewer.profilePic]];
}

@end
