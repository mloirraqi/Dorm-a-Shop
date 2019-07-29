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

//properties saved in server
@property (nonatomic, strong) NSString *postID;
@property (nonatomic, strong) PFUser *author;
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) PFFileObject *image;
@property (nonatomic, strong) PFGeoPoint *location;
@property (nonatomic, strong) NSNumber *price;
@property (nonatomic, assign) BOOL sold;

@end

NS_ASSUME_NONNULL_END
