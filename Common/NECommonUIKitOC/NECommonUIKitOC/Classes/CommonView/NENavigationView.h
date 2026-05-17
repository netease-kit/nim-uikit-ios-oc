// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 自定义导航栏视图
/// 包含返回按钮 (backButton)、标题 (navTitle)、更多按钮 (moreButton) 和底部分割线
@interface NENavigationView : UIView

@property (nonatomic, assign) CGFloat bottomMargin;   ///< 默认 12
@property (nonatomic, assign) CGFloat leftMargin;     ///< 默认 20

@property (nonatomic, strong, nullable) NSLayoutConstraint *titleBarBottomLineHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *backButtonWidthAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *moreButtonWidthAnchor;

@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UILabel *navTitle;
@property (nonatomic, strong, readonly) UIButton *moreButton;
@property (nonatomic, strong, readonly) UIView *titleBarView;
@property (nonatomic, strong, readonly) UIView *titleBarBottomLine;

- (void)setupUI;

- (void)setBackButtonTitle:(NSString *)title;
- (void)setBackButtonImage:(nullable UIImage *)image;
- (void)setBackButtonWidth:(CGFloat)width;
- (void)addBackButtonTarget:(id)target selector:(SEL)selector;

- (void)setMoreButtonTitle:(NSString *)title;
- (void)setMoreButtonTitle:(NSString *)title color:(UIColor *)color;
- (void)setMoreButtonImage:(nullable UIImage *)image;
- (void)setMoreButtonWidth:(CGFloat)width;
- (void)addMoreButtonTarget:(id)target selector:(SEL)selector;

- (void)setTitleBarBottomLineHeight:(CGFloat)height;
- (void)setNavigationBackgroundColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END