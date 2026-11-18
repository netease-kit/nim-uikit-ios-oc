// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEPagingItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEPagingStateKind) {
  NEPagingStateKindEmpty = 0,
  NEPagingStateKindSelected = 1,
  NEPagingStateKindScrolling = 2,
};

@interface NEPagingState : NSObject <NSCopying>

@property (nonatomic, assign, readonly) NEPagingStateKind kind;
@property (nonatomic, strong, readonly, nullable) id<NEPagingItem> currentPagingItem;
@property (nonatomic, strong, readonly, nullable) id<NEPagingItem> upcomingPagingItem;
@property (nonatomic, assign, readonly) CGFloat progress;
@property (nonatomic, assign, readonly) CGPoint initialContentOffset;
@property (nonatomic, assign, readonly) CGFloat distance;
@property (nonatomic, strong, readonly, nullable) id<NEPagingItem> visuallySelectedPagingItem;

+ (instancetype)emptyState;
+ (instancetype)selectedStateWithPagingItem:(id<NEPagingItem>)pagingItem;
+ (instancetype)scrollingStateWithPagingItem:(id<NEPagingItem>)pagingItem
                           upcomingPagingItem:(nullable id<NEPagingItem>)upcomingPagingItem
                                     progress:(CGFloat)progress
                         initialContentOffset:(CGPoint)initialContentOffset
                                     distance:(CGFloat)distance;

@end

NS_ASSUME_NONNULL_END
