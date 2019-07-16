//
//  Post.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "Post.h"
#import <Parse/Parse.h>


@implementation Post

@dynamic postID;
@dynamic author;
@dynamic caption;
@dynamic image;
@dynamic watchCount;
@dynamic datePosted;
@dynamic arrayOfUsersWatching;
@dynamic category;
@dynamic condition;
@dynamic price;
@dynamic title;

+ (nonnull NSString *)parseClassName {
    return @"Post";
}

+ (void) postListing: ( UIImage * _Nullable )image withCaption: ( NSString * _Nullable )caption withPrice: ( NSNumber * _Nullable )price withCondition:(NSString * _Nullable)condition withCategory:(NSString * _Nullable)category withTitle:(NSString * _Nullable)title withCompletion: (PFBooleanResultBlock  _Nullable)completion {
    Post *newPost = [Post new];
    newPost.image = [self getPFFileFromImage:image];
    newPost.author = [PFUser currentUser];
    newPost.caption = caption;
    newPost.condition = condition;
    newPost.title = title;

    newPost.arrayOfUsersWatching = [[NSMutableArray alloc] init];
    
    newPost.watchCount = @(0);
    newPost.price = price;
    newPost.datePosted = [NSDate date];
    
    [newPost saveInBackgroundWithBlock: completion];
}

+ (PFFileObject *)getPFFileFromImage: (UIImage * _Nullable)image {
    // check if image is not nil
    if (!image) {
        return nil;
    }
    
    NSData *imageData = UIImagePNGRepresentation(image);
    // get image data and check if that is not nil
    if (!imageData) {
        return nil;
    }
    
    return [PFFileObject fileObjectWithName:@"image.png" data:imageData];
}

@end
