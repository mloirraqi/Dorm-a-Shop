//
//  ConversationCoreData+CoreDataClass.h
//  
//
//  Created by addisonz on 7/30/19.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Conversation.h"
@import Parse;

@class UserCoreData;

NS_ASSUME_NONNULL_BEGIN

@interface ConversationCoreData : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "ConversationCoreData+CoreDataProperties.h"
