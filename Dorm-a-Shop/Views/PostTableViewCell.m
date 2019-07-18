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
    
    [self setWatched:[PFUser currentUser] forPost:post];
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    
    self.priceLabel.text = [NSString stringWithFormat:@"$%@", post.price];
}

- (void)setWatched:(PFUser *)user forPost:(Post *)post{
    PFQuery *watchQuery = [PFQuery queryWithClassName:@"Watches"];
    [watchQuery orderByDescending:@"createdAt"];
    [watchQuery includeKey:@"user"];
    [watchQuery whereKey:@"userID" equalTo:user.objectId];
    [watchQuery whereKey:@"postID" equalTo:post.objectId];
    
    __weak PostTableViewCell *weakSelf = self;
    [watchQuery findObjectsInBackgroundWithBlock:^(NSArray<PFObject *> * _Nullable watches, NSError * _Nullable error) {
        if (error) {
            NSLog(@"😫😫😫 Error getting watch query: %@", error.localizedDescription);
        }
        else if (watches.count > 0) {
            weakSelf.watch = watches[0];
            weakSelf.watchButton.selected = YES;
            [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%@ watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
        } else {
            weakSelf.watch = nil;
            weakSelf.watchButton.selected = NO;
            [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%@ watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
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
                
                int watchCountInt = [weakSelf.post.watchCount intValue];
                watchCountInt --;
                weakSelf.post.watchCount = [NSNumber numberWithInt:watchCountInt];
                
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Watch (%@ watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
                
                [weakSelf.post setObject:self.post.watchCount forKey:@"watchCount"];
                [weakSelf.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error != nil) {
                        NSLog(@"Post watchCount update failed: %@", error.localizedDescription);
                    }
                }];
            } else {
                NSLog(@"Delete watch object (user/post pair) in database failed: %@", error.localizedDescription);
            }
        }];
    } else {
        PFObject *watch = [PFObject objectWithClassName:@"Watches"];
        watch[@"postID"] = self.post.objectId;
        watch[@"userID"] = [PFUser currentUser].objectId;
        
        [watch saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            if (succeeded) {
                weakSelf.watch = watch;
                weakSelf.watchButton.selected = YES;
                
                int watchCountInt = [weakSelf.post.watchCount intValue];
                watchCountInt ++;
                weakSelf.post.watchCount = [NSNumber numberWithInt:watchCountInt];
                
                [weakSelf.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%@ watching)", weakSelf.post.watchCount] forState:UIControlStateNormal];
                
                [weakSelf.post setObject:weakSelf.post.watchCount forKey:@"watchCount"];
                [weakSelf.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error != nil) {
                        NSLog(@"Post watchCount update failed: %@", error.localizedDescription);
                    }
                }];
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
