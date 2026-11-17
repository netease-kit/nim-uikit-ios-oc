// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

#import "ChatNavigationView.h"
#import "FunChatUIColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEChatBaseViewController : UIViewController <UIGestureRecognizerDelegate>

/// 顶部导航栏高度常量，设置时自动更新约束
@property (nonatomic, assign) CGFloat topConstant;

/// 自定义导航栏高度布局约束
@property (nonatomic, strong, nullable) NSLayoutConstraint *navigationViewHeightAnchor;

/// 自定义导航栏
@property (nonatomic, strong) ChatNavigationView *navigationView;

/// 空数据占位视图（getter-based lazy init）
@property (nonatomic, strong, readonly) NEEmptyDataView *emptyView;

/// 普通机型仍由页面自身呈现。
- (UIViewController *)documentPreviewPresenter;

- (void)presentAdaptivePreview:(UIViewController *)controller
                      animated:(BOOL)animated
                    completion:(void (^_Nullable)(void))completion;

- (void)setupBackUI;
- (void)backEvent;
- (void)toSetting;
- (void)addLeftSwipeDismissGesture;

/// 显示底部视频/拍照选择面板
- (void)showBottomVideoAction:(UIViewController *)target cameraOnly:(BOOL)cameraOnly;
/// 兼容 Fun 主题旧命名
- (void)showCustomBottomVideoAction:(UIViewController *)target isVideo:(BOOL)isVideo;
/// 兼容 Fun 主题旧命名
- (void)showSingleAlert:(NSString *)message completion:(void(^)(void))completion;
/// 添加右侧导航按钮
- (void)addRightAction:(UIImage *)image action:(SEL)action target:(id)target;

@end

NS_ASSUME_NONNULL_END
