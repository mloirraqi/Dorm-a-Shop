//
//  PostCoreData+CoreDataProperties.h
//  
//
//  Created by ilanashapiro on 7/25/19.
//
//

#import "PostCoreData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface PostCoreData (CoreDataProperties)

+ (NSFetchRequest<PostCoreData *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *caption;
@property (nullable, nonatomic, copy) NSString *category;
@property (nullable, nonatomic, copy) NSString *condition;
@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nullable, nonatomic, retain) NSData *image;
@property (nullable, nonatomic, copy) NSString *location;
@property (nullable, nonatomic, copy) NSString *objectId;
@property (nonatomic) double price;
@property (nonatomic) BOOL sold;
@property (nullable, nonatomic, copy) NSString *title;
@property (nonatomic) int64_t watchCount;
@property (nonatomic) BOOL watched;
@property (nullable, nonatomic, copy) NSString *watchObjectId;
@property (nullable, nonatomic, retain) UserCoreData *author;

@end

NS_ASSUME_NONNULL_END
