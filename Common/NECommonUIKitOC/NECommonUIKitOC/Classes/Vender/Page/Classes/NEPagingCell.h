// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingOptions;
@protocol NEPagingItem;

@interface NEPagingCell : UICollectionViewCell

- (void)setPagingItem:(id<NEPagingItem>)pagingItem
             selected:(BOOL)selected
              options:(NEPagingOptions *)options;

@end

NS_ASSUME_NONNULL_END
