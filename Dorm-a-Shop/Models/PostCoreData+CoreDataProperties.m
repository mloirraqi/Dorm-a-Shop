//
//  PostCoreData+CoreDataProperties.m
//  
//
//  Created by addisonz on 7/30/19.
//
//

#import "PostCoreData+CoreDataProperties.h"

@implementation PostCoreData (CoreDataProperties)

+ (NSFetchRequest<PostCoreData *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"PostCoreData"];
}

@dynamic caption;
@dynamic category;
@dynamic condition;
@dynamic createdAt;
@dynamic image;
@dynamic location;
@dynamic objectId;
@dynamic price;
@dynamic sold;
@dynamic title;
@dynamic watchCount;
@dynamic watched;
@dynamic watchObjectId;
@dynamic author;

@end
