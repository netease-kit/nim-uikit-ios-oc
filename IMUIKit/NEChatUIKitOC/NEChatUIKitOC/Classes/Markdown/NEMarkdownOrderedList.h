// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownLevelElement.h"

NS_ASSUME_NONNULL_BEGIN

/// 有序列表渲染 Element，支持多级缩进（1. 2. 等数字序号）
@interface NEMarkdownOrderedList : NSObject <NEMarkdownLevelElement>

@property (nonatomic, assign) NSInteger maxLevel;
@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *color;

- (instancetype)initWithFont:(nullable UIFont *)font;
- (instancetype)initWithFont:(nullable UIFont *)font maxLevel:(NSInteger)maxLevel color:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
