// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// NEUserHeaderView.h — 对齐 Swift NEUserHeaderView
// 支持 URL 头像加载 + 文字首字母占位 + uid 哈希背景色

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEUserHeaderView : UIImageView

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithImage:(nullable UIImage *)image NS_UNAVAILABLE;
- (instancetype)initWithImage:(nullable UIImage *)image
             highlightedImage:(nullable UIImage *)highlightedImage NS_UNAVAILABLE;

/// 文字占位 label（无头像时显示名称后两位）
@property (nonatomic, strong) UILabel *titleLabel;

/// 配置头像数据
/// @param headUrl  头像 URL，为空则显示文字占位
/// @param name     显示名称（用于截取后两位）
/// @param uid      用户/群 ID（用于计算背景色）
- (void)configHeadDataWithHeadUrl:(nullable NSString *)headUrl name:(NSString *)name uid:(NSString *)uid;
- (void)configHeadData:(nullable NSString *)headUrl name:(NSString *)name uid:(NSString *)uid;

/// 配置本地静态头像，并取消复用前尚未完成的网络头像请求。
- (void)configStaticImage:(nullable UIImage *)image;

/// 设置文字（自动截取后两位）
- (void)setTitle:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
