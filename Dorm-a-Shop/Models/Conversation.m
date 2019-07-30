//
//  Conversation.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/30/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "Conversation.h"

@implementation Conversation

@dynamic sender;
@dynamic receiver;
@dynamic lastText;

+ (nonnull NSString *)parseClassName {
    return @"Conversation";
}

@end
