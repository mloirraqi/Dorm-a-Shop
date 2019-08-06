//
//  NSNotificationCenter+MainThread.h
//  
//
//  Created by ilanashapiro on 8/5/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNotificationCenter (MainThread)

- (void)postNotificationOnMainThread:(NSNotification *)notification;
- (void)postNotificationOnMainThreadName:(NSString *)name object:(id _Nullable)object;
- (void)postNotificationOnMainThreadName:(NSString *)name object:(id _Nullable)object userInfo:(NSDictionary * _Nullable)userInfo;

@end

NS_ASSUME_NONNULL_END
