//
//  PostManager.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/19/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PostManager : NSObject {
    NSString *someProperty;
}

@property (nonatomic, retain) NSMutableArray *allPostsArray;

+ (id)shared;

@end

NS_ASSUME_NONNULL_END
