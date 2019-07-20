//
//  PostsManager.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PostsManager : NSObject {
    NSString *someProperty;
}

@property (nonatomic, retain) NSArray *allPostsArray;

+ (id)shared;

@end

NS_ASSUME_NONNULL_END
