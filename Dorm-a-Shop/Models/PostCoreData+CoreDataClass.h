//
//  PostCoreData+CoreDataClass.h
//  
//
//  Created by ilanashapiro on 7/30/19.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Watches.h"
#import "Post.h"

@class UserCoreData;

NS_ASSUME_NONNULL_BEGIN

@interface PostCoreData : NSManagedObject

@property (nullable, nonatomic, strong) Watches *watch;
@property (nullable, nonatomic, strong) Post *post;

@end

NS_ASSUME_NONNULL_END

#import "PostCoreData+CoreDataProperties.h"
