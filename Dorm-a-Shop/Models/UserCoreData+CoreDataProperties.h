//
//  UserCoreData+CoreDataProperties.h
//  
//
//  Created by ilanashapiro on 7/24/19.
//
//

#import "UserCoreData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface UserCoreData (CoreDataProperties)

+ (NSFetchRequest<UserCoreData *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *email;
@property (nullable, nonatomic, copy) NSString *location;
@property (nullable, nonatomic, copy) NSString *objectId;
@property (nullable, nonatomic, retain) NSData *profilePic;
@property (nullable, nonatomic, copy) NSString *username;
@property (nullable, nonatomic, retain) NSSet<PostCoreData *> *post;

@end

@interface UserCoreData (CoreDataGeneratedAccessors)

- (void)addPostObject:(PostCoreData *)value;
- (void)removePostObject:(PostCoreData *)value;
- (void)addPost:(NSSet<PostCoreData *> *)values;
- (void)removePost:(NSSet<PostCoreData *> *)values;

@end

NS_ASSUME_NONNULL_END
