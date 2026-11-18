// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///
/// 1. 场景几何能确认「侧边控件区」时直接采用；
///
/// 任何一步都不会在只有刘海/灵动岛的普通 iPhone 上返回 YES。
@interface NEAdaptiveDeviceGate : NSObject

///
@property (class, nonatomic, assign) BOOL adaptiveHostActive;

/// 清除宿主写入的标记，回到"按设备判定"。
+ (void)resetAdaptiveHostActive;

+ (BOOL)isFoldableDevice;

/// 场景几何判定（官方推荐路径）：单侧横向安全区 + 贴边竖向遮挡区。
+ (BOOL)foldableBySceneGeometry;

/// 机型判定；只接受机型标识符，模拟器额外读取 `SIMULATOR_MODEL_IDENTIFIER`。
+ (BOOL)isFoldableWithIdentifier:(NSString *)identifier
         simulatorModelIdentifier:(nullable NSString *)simulatorModelIdentifier
                     isSimulator:(BOOL)isSimulator;

/// 单个遮挡区是否代表 Duo 的「侧边控件区」：贴边、竖向、窄条。
+ (BOOL)isSideControlAreaWithFrame:(CGRect)frame
                        windowSize:(CGSize)windowSize
                          isActive:(BOOL)isActive;

+ (BOOL)isFoldableGeometryWithSafeAreaInsets:(UIEdgeInsets)safeAreaInsets
                                  windowSize:(CGSize)windowSize
                            activeOcclusions:(NSArray<NSValue *> *)activeOcclusions;

@end

@interface NEAdaptiveColumnGeometry : NSObject

/// 内容视图是否位于双栏展开态的右侧详情栏。
+ (BOOL)isDetailColumnWithFrameInWindow:(CGRect)frameInWindow
                           windowWidth:(CGFloat)windowWidth
                       safeAreaInsets:(UIEdgeInsets)safeAreaInsets;

@end

///
FOUNDATION_EXPORT CGFloat NEUIKitStatusBarHeight(void);

///
FOUNDATION_EXPORT CGFloat NEUIKitNavigationAndStatusHeight(void);

/// 以页面 view 的安全区为回退的状态栏高度。
///
/// iOS 27 冷启动/场景切换早期，`statusBarManager.statusBarFrame` 可能短暂为 0；
/// 页面在 `viewDidLoad` 用它算出的导航栏高度会被约束永久固定，表现为标题顶进状态栏。
FOUNDATION_EXPORT CGFloat NEUIKitStatusBarHeightForView(UIView *_Nullable view);

/// `44 + NEUIKitStatusBarHeightForView(view)`。
FOUNDATION_EXPORT CGFloat NEUIKitNavigationAndStatusHeightForView(UIView *_Nullable view);

/// 页面导航栏高度可动态刷新：安全区变化后由基类调用 `ne_refreshNavigationBarHeightIfNeeded`。
@protocol NENavigationBarHeightProviding <NSObject>
- (CGFloat)ne_navigationBarHeight;
- (void)ne_applyNavigationBarHeight:(CGFloat)height;
@end

@interface UIViewController (NENavigationBarMetrics)

/// 安全区/状态栏就绪后刷新自定义导航栏高度；未实现协议的页面自动跳过。
- (void)ne_refreshNavigationBarHeightIfNeeded;

@end

///
FOUNDATION_EXPORT CGFloat NEUIKitAdaptiveNavigationAndStatusHeight(void);

NS_ASSUME_NONNULL_END
