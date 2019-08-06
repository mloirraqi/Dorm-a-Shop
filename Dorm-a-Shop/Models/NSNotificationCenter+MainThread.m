//
//  NSNotificationCenter+MainThread.m
//  
//
//  Created by ilanashapiro on 8/5/19.
//

#import "NSNotificationCenter+MainThread.h"

@implementation NSNotificationCenter (MainThread)

- (void)postNotificationOnMainThread:(NSNotification *)notification {
    [self performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

- (void)postNotificationOnMainThreadName:(NSString *)name object:(id _Nullable)object {
    NSNotification *notification = [NSNotification notificationWithName:name object:object];
    [self postNotificationOnMainThread:notification];
}

- (void)postNotificationOnMainThreadName:(NSString *)name object:(id _Nullable)object userInfo:(NSDictionary * _Nullable)userInfo {
    NSNotification *notification = [NSNotification notificationWithName:name object:object userInfo:userInfo];
    [self postNotificationOnMainThread:notification];
}

@end
