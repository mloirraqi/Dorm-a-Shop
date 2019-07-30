//
//  Conversation.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/30/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Parse/Parse.h>
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface Conversation : PFObject

//inherits objectId from PFObject

@property (nonatomic, strong) User *sender;
@property (nonatomic, strong) User *receiver;
@property (nonatomic, strong) NSString *lastText;

@end

NS_ASSUME_NONNULL_END
