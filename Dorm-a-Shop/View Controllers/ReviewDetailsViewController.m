//
//  ReviewDetailsViewController.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/8/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "ReviewDetailsViewController.h"
#import "NSDate+DateTools.h"
#import "UserCoreData+CoreDataClass.h"
#import "UILabel+Boldify.h"

@interface ReviewDetailsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *reviewerLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *reviewLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *reviewerProfileImageView;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;

@end

@implementation ReviewDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dateLabel.text = [NSString stringWithFormat:@"%@", [self.review.dateWritten shortTimeAgoSinceNow]];
    self.reviewerLabel.text = self.review.reviewer.username;
    self.titleLabel.text = [NSString stringWithFormat:@"%@", self.review.title];
    self.ratingLabel.text = [NSString stringWithFormat:@"%d/5", (int)self.review.rating];
    self.reviewerProfileImageView.layer.cornerRadius = 15;
    self.reviewerProfileImageView.layer.masksToBounds = YES;
    [self.reviewerProfileImageView setImage:[UIImage imageWithData:self.review.reviewer.profilePic]];
    self.itemDescriptionLabel.text = [NSString stringWithFormat:@"Item description: %@", self.review.itemDescription];
    [self.itemDescriptionLabel boldSubstring:@"Item description:"];
    self.reviewLabel.text = [NSString stringWithFormat:@"Review: %@", self.review.review];
    [self.reviewLabel boldSubstring:@"Review:"];
}

@end
