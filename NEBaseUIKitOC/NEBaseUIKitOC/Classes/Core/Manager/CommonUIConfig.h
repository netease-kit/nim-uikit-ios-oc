// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// CommonUIKit 全局 UI 配置单例
@interface CommonUIConfig : NSObject

@property (nonatomic, class, readonly) CommonUIConfig *shared;

/// 导航栏返回按钮图片
@property (nonatomic, strong, nullable) UIImage *backArrowImage;

@end

NS_ASSUME_NONNULL_END