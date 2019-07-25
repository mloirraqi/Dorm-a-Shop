//
//  User.h
//  
//
//  Created by ilanashapiro on 7/25/19.
//

#import <Parse/Parse.h>

NS_ASSUME_NONNULL_BEGIN

@interface User : PFUser

@property (nonatomic, strong) PFFileObject *profilePic;
@property (nonatomic, strong) PFGeoPoint *location;

@end

NS_ASSUME_NONNULL_END
