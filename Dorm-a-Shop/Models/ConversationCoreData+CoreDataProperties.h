//
//  ConversationCoreData+CoreDataProperties.h
//  
//
//  Created by addisonz on 7/30/19.
//
//

#import "ConversationCoreData+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ConversationCoreData (CoreDataProperties)

+ (NSFetchRequest<ConversationCoreData *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nullable, nonatomic, copy) NSString *lastText;
@property (nullable, nonatomic, copy) NSString *objectId;
@property (nullable, nonatomic, retain) UserCoreData *receiver;
@property (nullable, nonatomic, retain) UserCoreData *sender;

@end

NS_ASSUME_NONNULL_END
