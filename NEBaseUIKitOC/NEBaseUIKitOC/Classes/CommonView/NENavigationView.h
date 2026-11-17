// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 自定义导航栏视图
/// 包含返回按钮 (backButton)、标题 (navTitle)、更多按钮 (moreButton) 和底部分割线
/// 导航栏动作（返回 / 右侧按钮）的文案、图标、启用态或显隐发生变化。
///
UIKIT_EXTERN NSNotificationName const NENavigationViewDidChangeActionsNotification;

@interface NENavigationView : UIView

@property (nonatomic, assign) CGFloat bottomMargin;   ///< 默认 12
@property (nonatomic, assign) CGFloat leftMargin;     ///< 默认 20

@property (nonatomic, assign) CGFloat titleBarTopCompensation;

@property (nonatomic, strong, nullable) NSLayoutConstraint *titleBarBottomLineHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleBarBottomCompensationAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *backButtonWidthAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *moreButtonWidthAnchor;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIView *titleBarView;
@property (nonatomic, strong) UIView *titleBarBottomLine;

- (void)setupUI;

- (void)setBackButtonTitle:(NSString *)title;
- (void)setBackButtonImage:(nullable UIImage *)image;
- (void)setBackButtonWidth:(CGFloat)width;
- (void)addBackButtonTargetWithTarget:(nullable id)target selector:(SEL)selector;
- (void)addBackButtonTarget:(id)target selector:(SEL)selector;

- (void)setMoreButtonTitle:(NSString *)title;
- (void)setMoreButtonTitle:(NSString *)title :(UIColor *)color;
- (void)setMoreButtonTitle:(NSString *)title color:(UIColor *)color;
- (void)setMoreButtonImage:(nullable UIImage *)image;
- (void)setMoreButtonWidth:(CGFloat)width;
- (void)addMoreButtonTargetWithTarget:(nullable id)target selector:(SEL)selector;
- (void)addMoreButtonTarget:(id)target selector:(SEL)selector;

/// 页面直接修改 `backButton` / `moreButton`（例如动态数量文案）后调用，
/// 通知外部容器重新读取导航栏动作。
- (void)notifyActionsChanged;

- (void)setTitleBarBottomLineHeight:(CGFloat)height;
- (void)setNavigationBackgroundColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
