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
    
    [self setWatchedUser:[PFUser currentUser] Post:post];
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}

- (void)setWatchedUser:(PFUser *)user Post:(Post *)post{
    PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
    [watchQuery orderByDescending:@"createdAt"];
    [watchQuery whereKey:@"post" equalTo:post];
    
    __weak PostTableViewCell *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable postWatches, NSError * _Nullable error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
        } else {
            weakSelf.watchCount = postWatches.count;
            if (weakSelf.watchCount > 0) {
                bool watched = NO;
                for (PFObject *watch in postWatches) {
                    if ([((PFObject *)watch[@"user"]).objectId isEqualToString:user.objectId]) {
                        weakSelf.watchButton.selected = YES;
                        [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", weakSelf.watchCount] forState:UIControlStateSelected];
                        weakSelf.watch = watch;
                        watched = YES;
                        break;
                    }
                }
                
                if (!watched) {
                    weakSelf.watchButton.selected = NO;
                    [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", weakSelf.watchCount] forState:UIControlStateNormal];
                    weakSelf.watch = nil;
                }
            }
            else {
                weakSelf.watchButton.selected = NO;
                [weakSelf.watchButton setTitle:@"Watch (0 watching)" forState:UIControlStateNormal];
                weakSelf.watch = nil;
            }
        }
    }];
}

- (IBAction)didTapWatch:(id)sender {
    __weak PostTableViewCell *weakSelf = self;
    if (self.watchButton.selected) {
        [self.watch deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                weakSelf.watch = nil;
                weakSelf.watchButton.selected = NO;
                weakSelf.watchCount --;
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", weakSelf.watchCount] forState:UIControlStateNormal];
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:@NO,@"watch", weakSelf.post, @"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:self userInfo:watchInfoDict];
            } else {
                NSLog(@"Delete watch object (user/post pair) in database failed: %@", error.localizedDescription);
            }
        }];
    } else {
        PFObject *watch = [PFObject objectWithClassName:@"Watches"];
        watch[@"post"] = self.post;
        watch[@"user"] = [PFUser currentUser];
        
        [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                weakSelf.watch = watch;
                weakSelf.watchButton.selected = YES;
                weakSelf.watchCount ++;
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", weakSelf.watchCount] forState:UIControlStateNormal];
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:@YES,@"watchState", weakSelf.post, @"post", weakSelf.watch, @"watch", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:self userInfo:watchInfoDict];
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
