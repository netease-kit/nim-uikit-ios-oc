// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (NEAdditions)

@property (nonatomic, assign) BOOL neShouldIgnoreScrollingAdjustment;
@property (nonatomic, assign) BOOL neShouldIgnoreContentInsetAdjustment;
@property (nonatomic, assign) BOOL neShouldRestoreScrollViewContentOffset;

@end

@interface UITableView (NEAdditions)

- (nullable NSIndexPath *)nePreviousIndexPathOf:(NSIndexPath *)indexPath;

@end

@interface UICollectionView (NEAdditions)

- (nullable NSIndexPath *)nePreviousIndexPathOf:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
