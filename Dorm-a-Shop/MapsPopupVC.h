//
//  MapsPopupVC.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 8/04/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Card.h"
#import "CoreDataManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface MapsPopupVC : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UserCoreData* userCoreData;

@end

NS_ASSUME_NONNULL_END
