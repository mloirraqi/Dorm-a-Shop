//
//  Card.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 07/24/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "UserCoreData+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface Card : NSObject

@property (nonatomic, strong) UserCoreData *author;
@property (nonatomic, strong) NSMutableArray *posts;

- (instancetype)initWithUser:(UserCoreData *)user postsArray:(NSMutableArray *)postsArray;

@end

NS_ASSUME_NONNULL_END
