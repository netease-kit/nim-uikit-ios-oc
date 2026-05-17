// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEPagingViewControllerInfiniteDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEPagingFiniteDataSource : NSObject <NEPagingViewControllerInfiniteDataSource>

@property (nonatomic, copy) NSArray<id<NEPagingItem>> *items;
@property (nonatomic, copy, nullable) UIViewController * _Nullable (^viewControllerForIndex)(NSInteger index);

@end

NS_ASSUME_NONNULL_END
