//
//  Post.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

NS_ASSUME_NONNULL_BEGIN

@interface Post : PFObject <PFSubclassing>

@property (nonatomic, strong) NSString *postID;
@property (nonatomic, strong) PFUser *author;
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) PFFileObject *image;
@property (nonatomic, strong) NSNumber *watchCount;
@property (nonatomic, strong) NSNumber *price;
@property (nonatomic, strong) NSDate *datePosted;
@property (nonatomic, strong) NSMutableArray *arrayOfUsersWatching;

@end

NS_ASSUME_NONNULL_END
