// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingOptions;
@protocol NEPagingItem;

@interface NEPagingSizeCache : NSObject

@property (nonatomic, strong) NEPagingOptions *options;
@property (nonatomic, assign) BOOL implementsSizeDelegate;
@property (nonatomic, copy, nullable) CGFloat (^sizeForPagingItem)(id<NEPagingItem> pagingItem, BOOL selected);

- (instancetype)initWithOptions:(NEPagingOptions *)options;
- (void)clear;
- (CGFloat)itemSizeForPagingItem:(id<NEPagingItem>)pagingItem;
- (CGFloat)itemWidthSelectedForPagingItem:(id<NEPagingItem>)pagingItem;

@end

NS_ASSUME_NONNULL_END
