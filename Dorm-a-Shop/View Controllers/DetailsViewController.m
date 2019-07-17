//
//  DetailsViewController.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "DetailsViewController.h"
#import "Post.h"
@import Parse;

@interface DetailsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *postPFImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionLabel;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UIButton *sellerButton;
@property (weak, nonatomic) IBOutlet UIButton *watchButton;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setPostDetailContents:self.post];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self isMovingFromParentViewController]) {
        [self.delegate updateData:self];
    }
}

- (void)setPostDetailContents:(Post *)post {
    _post = post;
    
    self.postPFImageView.file = post[@"image"];
    [self.postPFImageView loadInBackground];
    
    self.numberWatchingLabel.text = [NSString stringWithFormat:@"%@ watching", post.watchCount];
    
    [self setWatched:[PFUser currentUser]];
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
