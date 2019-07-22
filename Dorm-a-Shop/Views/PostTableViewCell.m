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
//isInialReload not working, gets set YES thru prepare for reuse when watch button is clicked
@property (nonatomic) BOOL isInitialReload;

- (IBAction)didTapWatch:(id)sender;
- (IBAction)didTapProfile:(id)sender;

@end

@implementation PostTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.isInitialReload = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isInitialReload = YES;
}

- (void)setPost:(Post *)post {
    _post = post;
    
    [self.postPFImageView setImage:[UIImage imageNamed:@"item_placeholder"]];
    self.postPFImageView.file = post[@"image"];
    [self.postPFImageView loadInBackground];
    
    if (self.isInitialReload) {
        [self setUIWatchedForUser:[PFUser currentUser] Post:post];
        self.isInitialReload = NO;
    } else if (self.post.watch != nil) {
        self.watchButton.selected = YES;
        [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", self.post.watchCount] forState:UIControlStateSelected];
    } else {
        self.watchButton.selected = NO;
        [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", self.post.watchCount] forState:UIControlStateSelected];
    }
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}

- (void)receiveNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"ChangedWatchNotification"]) {
        NSNumber *watched = [[notification userInfo] objectForKey:@"watchStatus"];
        if (watched) {
            self.post.watchCount ++;
            self.watchButton.selected = YES;
            [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", self.post.watchCount] forState:UIControlStateSelected];
            self.post.watch = [[notification userInfo] objectForKey:@"watch"];;
        } else {
            self.post.watchCount --;
            self.watchButton.selected = NO;
            [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", self.post.watchCount] forState:UIControlStateSelected];
            self.post.watch = [[notification userInfo] objectForKey:@"watch"];
        }
    }
}

- (void)setUIWatchedForUser:(PFUser *)user Post:(Post *)post{
    /*PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
    [watchQuery orderByDescending:@"createdAt"];
    [watchQuery whereKey:@"post" equalTo:post];
    
    __weak PostTableViewCell *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable postWatches, NSError * _Nullable error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
        } else {
            weakSelf.post.watchCount = postWatches.count;
            if (weakSelf.post.watchCount > 0) {
                bool watched = NO;
                for (PFObject *watch in postWatches) {
                    if ([((PFObject *)watch[@"user"]).objectId isEqualToString:user.objectId]) {
                        weakSelf.watchButton.selected = YES;
                        [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", weakSelf.post.watchCount] forState:UIControlStateSelected];
                        weakSelf.post.watch = watch;
                        watched = YES;
                        break;
                    }
                }
                if (!watched) {
                    weakSelf.watchButton.selected = NO;
                    [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
                    weakSelf.post.watch = nil;
                }
            } else {
                weakSelf.watchButton.selected = NO;
                [weakSelf.watchButton setTitle:@"Watch (0 watching)" forState:UIControlStateNormal];
                weakSelf.post.watch = nil;
            }
        }
    }];*/
    
    /*__weak PostTableViewCell *weakSelf = self;
    [[PostManager shared] getCurrentUserWatchStatusForPost:post withCompletion:^(Post * _Nonnull post, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
        } else {
            if (post.watch != nil) {
                weakSelf.watchButton.selected = YES;
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", weakSelf.post.watchCount] forState:UIControlStateSelected];
            } else {
                weakSelf.watchButton.selected = NO;
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
            }
        }
    }];*/
    NSMutableArray *watchedPosts;
    if (((PostManager *)[PostManager shared]).watchedPostsArray != nil) {
        watchedPosts = ((PostManager *)[PostManager shared]).watchedPostsArray;
        if ([watchedPosts containsObject:post]) {
            self.watchButton.selected = YES;
            [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", self.post.watchCount] forState:UIControlStateSelected];
        } else {
            self.watchButton.selected = NO;
            [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", self.post.watchCount] forState:UIControlStateNormal];
        }
    } else {
        [[PostManager shared] getWatchedPostsForCurrentUserWithCompletion:^(NSMutableArray * _Nonnull watchedPostsArray, NSError * _Nonnull error) {
            if (error) {
                NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
            } else {
                if ([watchedPostsArray containsObject:post]) {
                    self.watchButton.selected = YES;
                    [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", self.post.watchCount] forState:UIControlStateSelected];
                } else {
                    self.watchButton.selected = NO;
                    [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", self.post.watchCount] forState:UIControlStateNormal];
                }
            }
        }];
    }
}

- (IBAction)didTapWatch:(id)sender {
    __weak PostTableViewCell *weakSelf = self;
    if (self.watchButton.selected) {
        [[PostManager shared] unwatchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
//                weakSelf.watchButton.selected = NO;
//                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lu watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
                
                NSDictionary *watchInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:weakSelf.post, @"post", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ChangedWatchNotification" object:weakSelf userInfo:watchInfoDict];
            } else {
                NSLog(@"Delete watch object (user/post pair) in database failed: %@", error.localizedDescription);
            }
        }];
    } else {
        [[PostManager shared] watchPost:self.post withCompletion:^(NSError * _Nonnull error) {
            if (!error) {
//                weakSelf.watchButton.selected = YES;
//                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lu watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
                
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
