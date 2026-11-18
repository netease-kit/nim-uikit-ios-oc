// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 与皮肤无关的公共默认色。
///
/// 这样任一端换肤或客户替换主题时不会把另一套皮肤的颜色带进来。
/// 取值与 `NormalUI` 当前视觉值一致，替换不产生视觉变化。
@interface UIColor (NEUIKitDefault)

/// 主色（当前 #337EFF）
@property(class, nonatomic, readonly) UIColor *ne_defaultPrimaryColor;
/// 页面底色（当前 #EDEDED）
@property(class, nonatomic, readonly) UIColor *ne_defaultPageBackgroundColor;
/// 分割线（当前 #E5E5E5）
@property(class, nonatomic, readonly) UIColor *ne_defaultLineColor;
/// 导航条底部分割线（当前 #E9EFF5）
@property(class, nonatomic, readonly) UIColor *ne_defaultNavigationDividerColor;
/// 回复条底色（当前 #EFF1F2）
@property(class, nonatomic, readonly) UIColor *ne_defaultReplyBackgroundColor;

@end

NS_ASSUME_NONNULL_END
