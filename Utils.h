//
//  Utils.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"


@interface Utils : NSObject
{
    AppDelegate *delegate;
}

+(Utils*) sharedInstance;

-(NSString*) getFromUserDefaults:(NSString*)key;
-(void) setUserDefaultsValue:(NSString*)value ForKey:(NSString*)key;

-(BOOL) isAnEmail:(NSString*)emailID;
-(BOOL)isValidEmail:(NSString*)email;


@end
