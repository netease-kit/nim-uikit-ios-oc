// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 所有业务 Cell 的基类，提供分隔线控制和统一 reuse 标识
@interface NEBaseTableViewCell : UITableViewCell

/// 底部分隔线视图
@property (nonatomic, strong, readonly) UIView *separatorLine;

/// 分隔线左侧内缩量，默认 16
@property (nonatomic, assign) CGFloat separatorInsetLeft;

/// 分隔线是否隐藏，默认 NO
@property (nonatomic, assign) BOOL separatorHidden;

/// 统一 reuseIdentifier
+ (NSString *)reuseId;

/// 子类重写以添加子视图和约束
- (void)setupSubviews;

@end

NS_ASSUME_NONNULL_END
