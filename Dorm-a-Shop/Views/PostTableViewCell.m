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
//#import "Post.h"
#import "PostManager.h"
#import "PostCoreData+CoreDataClass.h"
@import Parse;

@interface PostTableViewCell()

@property (nonatomic) BOOL isInitialReload;

- (IBAction)didTapWatch:(id)sender;
- (IBAction)didTapProfile:(id)sender;

@end

@implementation PostTableViewCell

- (void)setPost:(PostCoreData *)post {
    _post = post;
    
    [self.postImageView setImage:[UIImage imageNamed:@"item_placeholder"]];
    if (post.image) {
        [self.postImageView setImage:[UIImage imageWithData:post.image]];
    }
    
    //instead of [PFUser currentUser], should i query core data to get current user?????
    //[self setUIWatchedForUser:[PFUser currentUser] Post:post];
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

/*- (void)setUIWatchedForUser:(PFUser *)user Post:(PostCoreData *)post{
    __weak PostTableViewCell *weakSelf = self;
    [[PostManager shared] getCurrentUserWatchStatusForPost:post withCompletion:^(PostCoreData * _Nonnull post, NSError * _Nonnull error) {
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
}*/

- (IBAction)didTapWatch:(id)sender {
    __weak PostTableViewCell *weakSelf = self;
    if (self.watchButton.selected) {
        [[PostManager shared] unwatchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post, @"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            }
        }];
    } else {
        [[PostManager shared] watchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post, @"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
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
