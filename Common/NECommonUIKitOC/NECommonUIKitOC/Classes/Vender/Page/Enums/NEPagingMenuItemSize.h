// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEPagingMenuItemSizingMode) {
  NEPagingMenuItemSizingModeFixed = 0,
  NEPagingMenuItemSizingModeSizeToFit = 1,
  NEPagingMenuItemSizingModeSelfSizing = 2,
};

@interface NEPagingMenuItemSize : NSObject <NSCopying>

@property (nonatomic, assign, readonly) CGFloat width;
@property (nonatomic, assign, readonly) CGFloat minimumWidth;
@property (nonatomic, assign, readonly) CGFloat height;
@property (nonatomic, assign, readonly) NEPagingMenuItemSizingMode sizingMode;
@property (nonatomic, assign, readonly, getter=isHidden) BOOL hidden;

+ (instancetype)fixedWidth:(CGFloat)width height:(CGFloat)height;
+ (instancetype)sizeToFitMinWidth:(CGFloat)minimumWidth height:(CGFloat)height;
+ (instancetype)selfSizingEstimatedWidth:(CGFloat)estimatedWidth height:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
