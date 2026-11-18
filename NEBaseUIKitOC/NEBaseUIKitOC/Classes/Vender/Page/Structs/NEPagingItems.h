// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEPagingDirection.h"
#import "NEPagingItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEPagingItems : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSArray<id<NEPagingItem>> *items;
@property (nonatomic, assign, readonly) BOOL hasItemsBefore;
@property (nonatomic, assign, readonly) BOOL hasItemsAfter;

- (instancetype)initWithItems:(NSArray<id<NEPagingItem>> *)items
               hasItemsBefore:(BOOL)hasItemsBefore
                hasItemsAfter:(BOOL)hasItemsAfter;
- (nullable NSIndexPath *)indexPathForPagingItem:(id<NEPagingItem>)pagingItem;
- (id<NEPagingItem>)pagingItemForIndexPath:(NSIndexPath *)indexPath;
- (PagingDirection *)directionFrom:(id<NEPagingItem>)from
                                to:(id<NEPagingItem>)to;
- (BOOL)containsPagingItem:(id<NEPagingItem>)pagingItem;
- (NSArray<id<NEPagingItem>> *)unionWithItems:(NSArray<id<NEPagingItem>> *)newItems;

@end

NS_ASSUME_NONNULL_END
