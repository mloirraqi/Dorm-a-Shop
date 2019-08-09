//
//  User.h
//  
//
//  Created by ilanashapiro on 7/25/19.
//

#import <Parse/Parse.h>

NS_ASSUME_NONNULL_BEGIN

@interface User : PFUser

@property (nonatomic, strong) PFFileObject *ProfilePic;
@property (nonatomic, strong) PFGeoPoint *Location;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *username;

@end

NS_ASSUME_NONNULL_END
