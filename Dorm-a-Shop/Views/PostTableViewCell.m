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
        self.postImageView.layer.cornerRadius = 10;
        self.postImageView.layer.masksToBounds = YES;
    }
    
    self.watchButton.layer.cornerRadius = 5;
    [self.watchButton setSelected:self.post.watched];
    if (self.post.watched) {
        [self.watchButton setTitle:[NSString stringWithFormat:@"Unwatch (%lld)", self.post.watchCount] forState:UIControlStateSelected];
        
        [self.watchButton setTitleColor:[UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:0.8] forState:UIControlStateSelected];
        self.watchButton.titleLabel.backgroundColor = [UIColor whiteColor];
        self.watchButton.titleLabel.tintColor = [UIColor clearColor];
        self.watchButton.backgroundColor = [UIColor whiteColor];
        self.watchButton.tintColor = [UIColor clearColor];
        self.watchButton.layer.borderWidth = 1.0f;
        self.watchButton.layer.borderColor = [UIColor colorWithRed:0.0 green:122/255.0 blue:1.0 alpha:1].CGColor;
        self.watchButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    } else {
        [self.watchButton setTitle:[NSString stringWithFormat:@"Watch (%lld)", self.post.watchCount] forState:UIControlStateNormal];
        
        [self.watchButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        self.watchButton.titleLabel.backgroundColor = [UIColor whiteColor];
        self.watchButton.titleLabel.tintColor = [UIColor clearColor];
        self.watchButton.backgroundColor = [UIColor whiteColor];
        self.watchButton.tintColor = [UIColor clearColor];
        self.watchButton.layer.borderWidth = 1.0f;
        self.watchButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.watchButton.titleEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    }
    
    self.conditionLabel.text = post.condition;
    self.categoryLabel.text = post.category;
    self.titleLabel.text = post.title;
    self.priceLabel.text = [NSString stringWithFormat:@"$%.02f", post.price];
    self.hotnessLabel.hidden = YES;
    self.hotnessLabel.image = [self.hotnessLabel.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.hotnessLabel setTintColor:[UIColor colorWithRed:0.75 green:0.0 blue:0.0 alpha:1.0]];
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
