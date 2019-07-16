//
//  PostTableViewCell.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "PostTableViewCell.h"
#import "NSDate+DateTools.h"
#import "Post.h"
@import Parse;

@interface PostTableViewCell()

- (IBAction)didTapWatch:(id)sender;
- (IBAction)didTapProfile:(id)sender;

@end

@implementation PostTableViewCell

- (void)setPost:(Post *)post {
    _post = post;
    
    self.postPFImageView.file = post[@"image"];
    [self.postPFImageView loadInBackground];
    
    self.numberWatchingLabel.text = [NSString stringWithFormat:@"%@ watching", post.watchCount];
    
    if ([post.arrayOfUsersWatching containsObject:[PFUser currentUser].objectId]) {
        [self.watchButton setSelected:YES];
    }
    else {
        [self.watchButton setSelected:NO];
    }
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)didTapWatch:(id)sender {
    NSLog(@"Tapped like!");
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    // Retrieve the object by id
    [query getObjectInBackgroundWithId:self.post.objectId block:^(PFObject *postPFObject, NSError *error) {
        Post *post = (Post *)postPFObject;
        PFUser *user = [PFUser currentUser];
        if (![post.arrayOfUsersWatching containsObject:user.objectId]) {
            [self setWatched:YES forPost:post user:user];
        }
        else {
            [self setWatched:NO forPost:post user:user];
        }
    }];
}

- (IBAction)didTapProfile:(id)sender {
    
}

- (void)setWatched:(BOOL)watching forPost:(Post *)post user:(PFUser *)user {
    NSNumber *watchCountNumber = post.watchCount;
    int watchCountInt = [watchCountNumber intValue];
    
    if (watching) {
        [post.arrayOfUsersWatching addObject:user.objectId];
        watchCountNumber = [NSNumber numberWithInt:watchCountInt + 1];
        [self.watchButton setSelected:YES];/////
    }
    else {
        [post.arrayOfUsersWatching removeObject:user.objectId];
        watchCountNumber = [NSNumber numberWithInt:watchCountInt - 1];
        [self.watchButton setSelected:NO];/////
    }
    
    [post setObject:post.arrayOfUsersWatching forKey:@"arrayOfUsersWatching"];
    [post setObject:watchCountNumber forKey:@"watchCount"];
    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error != nil) {
            NSLog(@"Post list of users who liked update failed: %@", error.localizedDescription);
        }
        else {
            if ([post.watchCount intValue] == 1) {
                self.numberWatchingLabel.text = [NSString stringWithFormat:@"1 like"];
            }
            else {
                self.numberWatchingLabel.text = [NSString stringWithFormat:@"%@ likes", post.watchCount];
            }
            
            self.post.arrayOfUsersWatching = post.arrayOfUsersWatching; //set these values locally so we don't have to make a database request to update the view itself
            self.post.watchCount = post.watchCount;
            
            NSLog(@"Post list of users who liked successfully updated!");
        }
    }];
}

- (UIImage *)resizeImage:(UIImage *)image withSize:(CGSize)size {
    UIImageView *resizeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    
    resizeImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizeImageView.image = image;
    
    UIGraphicsBeginImageContext(size);
    [resizeImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
