//
//  User.m
//  
//
//  Created by ilanashapiro on 7/25/19.
//

#import "User.h"

@implementation User

@dynamic address;
@dynamic ProfilePic;
@dynamic Location;
@dynamic username;
@dynamic email;

+ (nonnull NSString *)parseClassName {
    return [super parseClassName];
}

//Since User is a subclass of PFUser, which is itself a subclass, it may not have a separate +parseClassName definitions. User should inherit +parseClassName from PFUser.

@end
