// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 尺寸类别；只用于诊断与快照比较，布局决策一律走几何 + 断点。
typedef NS_ENUM(NSInteger, NEWindowSizeClass) {
  NEWindowSizeClassUnspecified = 0,
  NEWindowSizeClassCompact,
  NEWindowSizeClassRegular,
};

/// 系统占位区类别：折痕 `division` 与硬件遮挡 `occlusion`。
typedef NS_ENUM(NSInteger, NEReservedRegionKind) {
  NEReservedRegionKindOcclusion = 0,
  NEReservedRegionKindDivision,
};

///
/// 尺寸计算；布局仍读取实时占位区。
@interface NEReservedRegionSnapshot : NSObject <NSCopying>

@property (nonatomic, assign, readonly) NEReservedRegionKind kind;
@property (nonatomic, assign, readonly) CGRect frame;

- (instancetype)initWithKind:(NEReservedRegionKind)kind frame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

/// 窗口事实快照；不可变，可安全跨回调传递与比较。
@interface NEWindowSnapshot : NSObject <NSCopying>

@property (nonatomic, assign, readonly) CGSize size;
@property (nonatomic, assign, readonly) CGFloat safeAreaTop;
@property (nonatomic, assign, readonly) CGFloat safeAreaLeft;
@property (nonatomic, assign, readonly) CGFloat safeAreaBottom;
@property (nonatomic, assign, readonly) CGFloat safeAreaRight;
@property (nonatomic, assign, readonly) NEWindowSizeClass horizontalSizeClass;
@property (nonatomic, assign, readonly) NEWindowSizeClass verticalSizeClass;
/// 窗口所在屏幕的 display scale。
@property (nonatomic, assign, readonly) CGFloat displayScale;
/// 当前激活的 division / occlusion 占位区，按类别与位置稳定排序。
@property (nonatomic, copy, readonly) NSArray<NEReservedRegionSnapshot *> *reservedRegions;

/// 占位区集合的稳定指纹，便于诊断与比较；相等性仍以 `reservedRegions` 为准。
@property (nonatomic, assign, readonly) uint64_t reservedRegionFingerprint;

- (instancetype)initWithSize:(CGSize)size
                 safeAreaTop:(CGFloat)safeAreaTop
                safeAreaLeft:(CGFloat)safeAreaLeft
              safeAreaBottom:(CGFloat)safeAreaBottom
               safeAreaRight:(CGFloat)safeAreaRight
          horizontalSizeClass:(NEWindowSizeClass)horizontalSizeClass
            verticalSizeClass:(NEWindowSizeClass)verticalSizeClass
                 displayScale:(CGFloat)displayScale
             reservedRegions:(NSArray<NEReservedRegionSnapshot *> *)reservedRegions NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// 从窗口当前状态采样；窗口为 nil 时返回 nil。
+ (nullable instancetype)snapshotWithWindow:(nullable UIWindow *)window;

/// 从视图当前状态采样（尺寸、安全区、trait、占位区都以该视图为准）；视图为 nil 时返回 nil。
+ (nullable instancetype)snapshotWithView:(nullable UIView *)view;

/// 与另一个快照逐字段比较（含占位区）。
- (BOOL)isEqualToSnapshot:(nullable NEWindowSnapshot *)other;

@end

typedef NEWindowSnapshot *_Nullable (^NEAdaptiveWindowSnapshotProvider)(void);

/// 窗口事实唯一入口：快照采集、相等去重、生命周期注销。
///
/// 宿主在 Scene 更新、根容器转场、安全区/trait 变化时调用 `refresh`；
@interface NEAdaptiveWindowContext : NSObject

/// 最近一次发布的快照；注销后为 nil。
@property (nonatomic, strong, readonly, nullable) NEWindowSnapshot *snapshot;

/// 由接入方提供采样闭包，便于宿主使用任意窗口/场景来源。
- (instancetype)initWithSample:(nullable NEAdaptiveWindowSnapshotProvider)sample
                      onChange:(void (^)(NEWindowSnapshot *snapshot))onChange NS_DESIGNATED_INITIALIZER;

/// 直接绑定窗口；内部弱引用窗口，窗口释放后下次采样返回 nil。
- (instancetype)initWithWindow:(UIWindow *)window
                      onChange:(void (^)(NEWindowSnapshot *snapshot))onChange;

/// 绑定窗口，并在同一窗口内优先采 `samplingView` 的事实。
///
/// 折叠/展开时窗口与视图的安全区会短暂不同步（真机实测 `view r88 / window r84`），
/// 而布局读取的是视图；传入外壳自己的视图可让快照与布局使用同一事实源。`samplingView`
/// 不属于该窗口时退回窗口采样。
- (instancetype)initWithWindow:(UIWindow *)window
                  samplingView:(nullable UIView *)samplingView
                      onChange:(void (^)(NEWindowSnapshot *snapshot))onChange;

- (void)refresh;
- (void)invalidate;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
