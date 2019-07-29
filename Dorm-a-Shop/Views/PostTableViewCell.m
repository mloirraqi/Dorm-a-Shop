//
//  PostTableViewCell.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "PostTableViewCell.h"
#import "NSDate+DateTools.h"
#import "WatchListViewController.h"
#import "Post.h"
#import "PostManager.h"
@import Parse;

@interface PostTableViewCell()

- (IBAction)didTapWatch:(id)sender;
- (IBAction)didTapProfile:(id)sender;

@end

@implementation PostTableViewCell

- (void)setPost:(Post *)post {
    _post = post;
    
    [self.postPFImageView setImage:[UIImage imageNamed:@"item_placeholder"]];
    self.postPFImageView.file = post[@"image"];
    [self.postPFImageView loadInBackground];
    
    [self setUIWatchedForUser:[PFUser currentUser] Post:post];
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}

- (void)setUIWatchedForUser:(PFUser *)user Post:(Post *)post{
    __weak PostTableViewCell *weakSelf = self;
    [[PostManager shared] getCurrentUserWatchStatusForPost:post withCompletion:^(Post * _Nonnull post, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
        } else {
            if (post.watch != nil) {
                weakSelf.watchButton.selected = YES;
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%@ watching)", weakSelf.post.watchCount] forState:UIControlStateSelected];
            } else {
                weakSelf.watchButton.selected = NO;
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%@ watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
            }
        }
    }];
}

- (IBAction)didTapWatch:(id)sender {
    __weak PostTableViewCell *weakSelf = self;
    if (self.watchButton.selected) {
        [[PostManager shared] unwatchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post, @"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            } else {
                NSLog(@"Delete watch object (user/post pair) in database failed: %@", error.localizedDescription);
            }
        }];
    } else {
        [[PostManager shared] watchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSLog(@"%@", weakSelf.post.watch);
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post, @"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            } else {
                NSLog(@"There was an error adding to watch class in database: %@", error.localizedDescription);
            }
        }];
    }
}

- (IBAction)didTapProfile:(id)sender {
    
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
