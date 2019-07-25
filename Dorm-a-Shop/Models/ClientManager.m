//
//  ClientManager.m
//  Dorm-a-Shop
//
//  Created by addisonz on 7/24/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "ClientManager.h"

@implementation ClientManager

@synthesize pfclient;

+ (instancetype)shared {
    static ClientManager *sharedClientManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClientManager = [[self alloc] init];
//        self->pfclient = [[PFLiveQueryClient alloc] init];
        
    });
    return sharedClientManager;
}
@end
