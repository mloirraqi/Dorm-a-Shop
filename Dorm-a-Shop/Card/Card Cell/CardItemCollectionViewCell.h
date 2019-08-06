//
//  CardItemCollectionViewCell.h
//  Dorm-a-Shop
//
//  Created by mloirraqi on 07/24/2019.
//  Copyright © 2019 ilanashapiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"
#import "PostCoreData+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface CardItemCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) PostCoreData *post;

@end

NS_ASSUME_NONNULL_END
