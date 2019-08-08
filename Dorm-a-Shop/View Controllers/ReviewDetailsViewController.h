//
//  ReviewDetailsViewController.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 8/8/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReviewCoreData+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReviewDetailsViewController : UIViewController

@property (nonatomic, strong) ReviewCoreData *review;

@end

NS_ASSUME_NONNULL_END
