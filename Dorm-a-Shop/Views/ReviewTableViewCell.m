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

@interface ReviewTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *sellerLabel;
@property (weak, nonatomic) IBOutlet UILabel *reviewerLabel;
@property (weak, nonatomic) IBOutlet UILabel *reviewDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UILabel *reviewLabel;

@end

@implementation ReviewTableViewCell

- (void)setPost:(ReviewCoreData *)review {
    _review = review;
    
    self.reviewDateLabel.text = [NSString stringWithFormat:@"%@", [review.dateWritten shortTimeAgoSinceNow]];
    self.reviewerLabel.text = review.reviewer.username;
    self.sellerLabel.text = review.seller.username;
    self.ratingLabel.text = [NSString stringWithFormat:@"%f", review.rating];
    self.reviewLabel.text = review.review;
}

@end
