//
//  Utils.m
//  Dorm-a-Shop
//
//  Created by mloirraqi on 7/17/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import "Utils.h"
#import <AddressBook/AddressBook.h>

@implementation Utils

static Utils* instance;

+(Utils*) sharedInstance
{
    if( instance == nil )
    {
        instance = [[Utils alloc] init];
    }
    
    return instance;
}

-(NSString*) getFromUserDefaults:(NSString*)key
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* objStr = [defaults objectForKey:key];
    
    return objStr;
}

-(void) setUserDefaultsValue:(NSString*)value ForKey:(NSString*)key
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

-(BOOL) isAnEmail:(NSString*)emailID
{
    if( ( [emailID rangeOfString:@"@" options:NSCaseInsensitiveSearch].location != NSNotFound ) &&
       ( [emailID rangeOfString:@".edu" options:NSCaseInsensitiveSearch].location != NSNotFound ) )
    {
        return true;
    }
    else
    {
        return false;
    }
}

#pragma mark --
#pragma mark Email Validation
-(BOOL)isValidEmail:(NSString*)email;
{
    BOOL returnBool=NO;
    
    
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    //Valid email address
    if ([emailTest evaluateWithObject:email] == YES)
    {
        returnBool=YES;
    }
    else
    {
        returnBool=NO;
        
    }
    return returnBool;
    
}

@end
