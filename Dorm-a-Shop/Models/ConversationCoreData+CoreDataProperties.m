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

@dynamic updatedAt;
@dynamic lastText;
@dynamic objectId;
@dynamic receiver;
@dynamic sender;

@end
