//
//  ConversationCoreData+CoreDataProperties.m
//  
//
//  Created by addisonz on 7/30/19.
//
//

#import "ConversationCoreData+CoreDataProperties.h"

@implementation ConversationCoreData (CoreDataProperties)

+ (NSFetchRequest<ConversationCoreData *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"ConversationCoreData"];
}

@dynamic createdAt;
@dynamic lastText;
@dynamic objectId;
@dynamic receiver;
@dynamic sender;

@end
