//
//  SwipePopupVC.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 8/8/19.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"
#import "CoreDataManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwipePopupVC : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UserCoreData* userCoreData;

@end

NS_ASSUME_NONNULL_END
