// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NEPagingItem;

@protocol NEPagingMenuDataSource <NSObject>

- (nullable id<NEPagingItem>)pagingItemBeforePagingItem:(id<NEPagingItem>)pagingItem;
- (nullable id<NEPagingItem>)pagingItemAfterPagingItem:(id<NEPagingItem>)pagingItem;

@end

NS_ASSUME_NONNULL_END
