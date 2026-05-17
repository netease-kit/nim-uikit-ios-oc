// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 通用空数据占位视图（图片 + 文字）
@interface NEEmptyDataView : UIView

/// 对齐 Swift 版的图片视图和尺寸约束
@property (nonatomic, strong, readonly) UIImageView *emptyImageView;
@property (nonatomic, strong, readonly, nullable) NSLayoutConstraint *widthConstraint;
@property (nonatomic, strong, readonly, nullable) NSLayoutConstraint *heightConstraint;

/// 占位图片，默认为 nil
@property (nonatomic, strong, nullable) UIImage *image;

/// 提示文字
@property (nonatomic, copy) NSString *message;

/// 提示文字颜色，默认 #999999
@property (nonatomic, strong) UIColor *messageColor;

/// 提示文字字号，默认 14pt
@property (nonatomic, assign) CGFloat messageFontSize;

/// 对齐 Swift 版构造方法
- (instancetype)initWithImageName:(NSString *)imageName
                          content:(NSString *)content
                            frame:(CGRect)frame;

- (instancetype)initWithImage:(nullable UIImage *)image
                      content:(NSString *)content
                        frame:(CGRect)frame;

/// 便捷方法：同时设置图片与文字
- (void)setImage:(nullable UIImage *)image message:(nullable NSString *)message;

/// 兼容旧调用：仅设置文案
- (void)setText:(nullable NSString *)text;

/// 设置富文本
- (void)setAttributedText:(nullable NSAttributedString *)att;

/// 兼容旧调用：按名称设置占位图
- (void)setEmptyImageName:(nullable NSString *)imageName;
- (void)setEmptyImageWithName:(nullable NSString *)imageName;

/// 对齐 Swift 版 API
- (void)setEmptyImage:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
