//
//  UILabel+Boldify.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/5/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

/*THIS CODE WAS WRITTEN BY USER Crazy Yoghurt ON STACKOVERFLOW ON SEP 14 2014:
 https://stackoverflow.com/questions/3586871/bold-non-bold-text-in-a-single-uilabel/33910728*/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (Boldify)

- (void) boldSubstring: (NSString*) substring;
- (void) boldRange: (NSRange) range;

@end

NS_ASSUME_NONNULL_END
