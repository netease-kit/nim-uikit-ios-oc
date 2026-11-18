// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

#import "NEChatDetailHostController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEChatDetailHostController (NEAdaptiveInternal)

- (void)setContentVisible:(BOOL)visible animated:(BOOL)animated;

@end

/// 内部实现：观察导航栈完成回调，并保留宿主原 delegate 的动画/交互/appearance 回调。
@interface NEAdaptiveNavigationObserver : NSObject <UINavigationControllerDelegate>

@property (nonatomic, weak, nullable) id<UINavigationControllerDelegate> originalDelegate;
@property (nonatomic, copy, nullable) void (^didShow)(void);
@property (nonatomic, copy, nullable) void (^willShow)(UIViewController *viewController);

- (instancetype)initWithNavigationController:(UINavigationController *)navigation
                                     didShow:(void (^)(void))didShow;

@end

/// 内部实现：单个分区的导航栈宿主。
///
/// 因此本类只负责内容栈的挂载、布局与 appearance 转发。
@interface NEAdaptiveSectionHost : UIViewController

@property (nonatomic, strong, readonly) UINavigationController *content;
@property (nonatomic, strong, readonly, nullable) UINavigationController *splitDetail;
@property (nonatomic, copy, nullable) UINavigationController *(^makeDetailNavigation)(void);
@property (nonatomic, copy, nullable) void (^onDetailNavigationCreated)(UINavigationController *navigation);
@property (nonatomic, copy, nullable) UIViewController *(^makeEmptyDetail)(void);
@property (nonatomic, copy, nullable) void (^onStackChanged)(void);
@property (nonatomic, assign, readonly) BOOL isShowingDetailPlaceholder;
@property (nonatomic, assign, readonly) BOOL hasDetailContent;
@property (nonatomic, assign, readonly) BOOL contentVisible;

- (instancetype)initWithContent:(UINavigationController *)content NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (void)detachContentForTransfer;
- (void)configureSplitWithMasterWidth:(nullable NSNumber *)masterWidth
                         dividerWidth:(CGFloat)dividerWidth
                         dividerColor:(UIColor *)dividerColor;
- (void)setVisible:(BOOL)visible;
- (void)resetDetail;

@end

NS_ASSUME_NONNULL_END
