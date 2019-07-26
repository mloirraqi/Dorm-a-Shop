//
//  UploadViewController.h
//  Dorm-a-Shop
//
//  Created by addisonz on 7/16/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "PostCoreData+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@protocol UploadViewControllerDelegate <NSObject>

- (void)didUpload:(PostCoreData *)post;

@end

@interface UploadViewController : UIViewController

@property (nonatomic, weak) id<UploadViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
