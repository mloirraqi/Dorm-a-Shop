//
//  MessageViewController.h
//  Dorm-a-Shop
//
//  Created by addisonz on 7/22/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface MessageViewController : UIViewController

@property (strong, nonatomic) PFUser *receiver;
@property (strong, nonatomic) PFObject *convo;
@property (strong, nonatomic) NSString *textBefore;

@end

NS_ASSUME_NONNULL_END
