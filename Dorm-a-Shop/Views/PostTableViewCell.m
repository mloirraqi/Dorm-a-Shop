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
#import "ParseDatabaseManager.h"
#import "PostCoreData+CoreDataClass.h"
#import "NSNotificationCenter+MainThread.h"
@import Parse;

@interface PostTableViewCell()

- (IBAction)didTapWatch:(id)sender;

@end

@implementation PostTableViewCell

- (void)setPost:(PostCoreData *)post {
    _post = post;
    
    [self.postImageView setImage:[UIImage imageNamed:@"item_placeholder"]];
    if (post.image) {
        [self.postImageView setImage:[UIImage imageWithData:post.image]];
    }

    [self.watchButton setSelected:self.post.watched];
    if (self.post.watched) {
        [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lld watching)", self.post.watchCount] forState:UIControlStateSelected];
    } else {
        [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lld watching)", self.post.watchCount] forState:UIControlStateNormal];
    }
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    self.priceLabel.text = [NSString stringWithFormat:@"$%f", post.price];
}

- (IBAction)didTapWatch:(id)sender {
    __weak PostTableViewCell *weakSelf = self;
    if (self.watchButton.selected) {
        [[ParseDatabaseManager shared] unwatchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post, @"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            } else {
                NSLog(@"Error unwatching post: %@", error.localizedDescription);
            }
        }];
    } else {
        [[ParseDatabaseManager shared] watchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post, @"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            } else {
                NSLog(@"Error watching post: %@", error.localizedDescription);
            }
        }];
    }
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
