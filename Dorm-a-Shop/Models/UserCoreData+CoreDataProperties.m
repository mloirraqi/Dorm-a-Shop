//
//  UserCoreData+CoreDataProperties.m
//  
//
//  Created by ilanashapiro on 7/30/19.
//
//

#import "UserCoreData+CoreDataProperties.h"

@implementation UserCoreData (CoreDataProperties)

+ (NSFetchRequest<UserCoreData *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"UserCoreData"];
}

@dynamic email;
@dynamic location;
@dynamic objectId;
@dynamic profilePic;
@dynamic username;
@dynamic post;

@end
