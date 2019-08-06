//
//  UILabel+Boldify.m
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/5/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

/*THIS CODE WAS WRITTEN BY USER Crazy Yoghurt ON STACKOVERFLOW ON SEP 14 2014:
 https://stackoverflow.com/questions/3586871/bold-non-bold-text-in-a-single-uilabel/33910728*/

#import "UILabel+Boldify.h"

@implementation UILabel (Boldify)

- (void)boldRange:(NSRange)range {
    if (![self respondsToSelector:@selector(setAttributedText:)]) {
        return;
    }
    
    NSMutableAttributedString *attributedText;
    if (!self.attributedText) {
        attributedText = [[NSMutableAttributedString alloc] initWithString:self.text];
    } else {
        attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    }
    
    [attributedText setAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:self.font.pointSize]} range:range];
    self.attributedText = attributedText;
}

- (void)boldSubstring:(NSString*)substring {
    NSRange range = [self.text rangeOfString:substring];
    [self boldRange:range];
}

@end
