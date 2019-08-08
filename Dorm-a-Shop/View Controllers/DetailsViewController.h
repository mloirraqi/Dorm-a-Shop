//
//  DetailsViewController.h
//  Dorm-a-Shop
//
//  Created by ilanashapiro on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "PostCoreData+CoreDataClass.h"
@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface DetailsViewController : UIViewController

@property (nonatomic, strong) PostCoreData *post;

@property (nonatomic, strong) NSIndexPath *indexPath;

@end

NS_ASSUME_NONNULL_END
