//
//  ClientManager.h
//  Dorm-a-Shop
//
//  Created by addisonz on 7/24/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
@import ParseLiveQuery;
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface ClientManager : NSObject

+ (id)shared;

@property (strong, nonatomic) PFLiveQueryClient *pfclient;
@property (strong, nonatomic) PFLiveQuerySubscription *subscription;


@end

NS_ASSUME_NONNULL_END
