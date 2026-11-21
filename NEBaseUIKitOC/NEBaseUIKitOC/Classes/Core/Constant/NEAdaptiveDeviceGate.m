// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAdaptiveDeviceGate.h"
#import "UIWindow+NEActiveKeyWindow.h"

#include <sys/utsname.h>

/// 宿主写入的能力标记；nil 表示未显式设置，按设备判定。
static NSNumber *NEAdaptiveHostActiveOverride = nil;

static NSString *NEAdaptiveFormatRect(CGRect rect) {
  return [NSString stringWithFormat:@"%.1f,%.1f %.1fx%.1f", rect.origin.x, rect.origin.y,
                                    rect.size.width, rect.size.height];
}

static NSString *NEAdaptiveFormatInsets(UIEdgeInsets insets) {
  return [NSString stringWithFormat:@"t%.1f l%.1f b%.1f r%.1f", insets.top, insets.left, insets.bottom,
                                    insets.right];
}

@interface NEAdaptiveDeviceGate ()
+ (nullable UIWindow *)activeWindow;
+ (BOOL)foldableByModel;
@end

@implementation NEAdaptiveDeviceGate

+ (BOOL)adaptiveHostActive {
  if (NEAdaptiveHostActiveOverride) {
    return NEAdaptiveHostActiveOverride.boolValue;
  }
  return [self isFoldableDevice];
}

+ (void)setAdaptiveHostActive:(BOOL)active {
  NEAdaptiveHostActiveOverride = @(active);
}

+ (void)resetAdaptiveHostActive {
  NEAdaptiveHostActiveOverride = nil;
}

+ (BOOL)isFoldableDevice {
  if ([self foldableBySceneGeometry]) {
    return YES;
  }
  return [self foldableByModel];
}

+ (NSString *)diagnosticDescription {
  NSMutableArray<NSString *> *parts = [NSMutableArray array];
  [parts addObject:[NSString stringWithFormat:@"adaptiveHost=%@",
                                              self.adaptiveHostActive ? @"YES" : @"NO"]];
  [parts addObject:[NSString stringWithFormat:@"foldable=%@ geometry=%@ model=%@",
                                              self.isFoldableDevice ? @"YES" : @"NO",
                                              self.foldableBySceneGeometry ? @"YES" : @"NO",
                                              self.foldableByModel ? @"YES" : @"NO"]];
  [parts addObject:[NSString stringWithFormat:@"UIScreen=%@",
                                              NEAdaptiveFormatRect(UIScreen.mainScreen.bounds)]];
  UIWindow *window = [self activeWindow];
  if (window) {
    [parts addObject:[NSString stringWithFormat:@"window=%@ safe=%@",
                                                NEAdaptiveFormatRect(window.bounds),
                                                NEAdaptiveFormatInsets(window.safeAreaInsets)]];
    UIWindowScene *scene = window.windowScene;
    if (scene) {
      CGRect statusBarFrame = scene.statusBarManager ? scene.statusBarManager.statusBarFrame : CGRectZero;
      [parts addObject:[NSString stringWithFormat:@"scene=%@ statusBar=%@",
                                                  NEAdaptiveFormatRect(scene.coordinateSpace.bounds),
                                                  NEAdaptiveFormatRect(statusBarFrame)]];
    }
    if (@available(iOS 27.1, *)) {
      NSMutableArray<NSString *> *occlusion = [NSMutableArray array];
      NSArray<UIViewReservedRegion *> *occlusionRegions =
          [window reservedRegionsOfKind:[UIViewReservedRegionKind occlusionRegionKind]];
      for (UIViewReservedRegion *region in occlusionRegions) {
        [occlusion addObject:[NSString stringWithFormat:@"%@:%@", NEAdaptiveFormatRect(region.frame),
                                                        region.isActive ? @"on" : @"off"]];
      }
      NSMutableArray<NSString *> *division = [NSMutableArray array];
      NSArray<UIViewReservedRegion *> *divisionRegions =
          [window reservedRegionsOfKind:[UIViewReservedRegionKind divisionRegionKind]];
      for (UIViewReservedRegion *region in divisionRegions) {
        [division addObject:[NSString stringWithFormat:@"%@:%@", NEAdaptiveFormatRect(region.frame),
                                                       region.isActive ? @"on" : @"off"]];
      }
      [parts addObject:[NSString stringWithFormat:@"occlusion=[%@] division=[%@]",
                                                  [occlusion componentsJoinedByString:@" "],
                                                  [division componentsJoinedByString:@" "]]];
    }
  } else {
    [parts addObject:@"window=nil"];
  }
  [parts addObject:[NSString stringWithFormat:@"statusBarHeight=%.1f", NEUIKitStatusBarHeight()]];
  return [parts componentsJoinedByString:@" "];
}

+ (BOOL)foldableBySceneGeometry {
  if (@available(iOS 27.1, *)) {
    UIWindow *window = [self activeWindow];
    if (!window) {
      return NO;
    }
    NSMutableArray<NSValue *> *occlusions = [NSMutableArray array];
    NSArray<UIViewReservedRegion *> *regions =
        [window reservedRegionsOfKind:[UIViewReservedRegionKind occlusionRegionKind]];
    for (UIViewReservedRegion *region in regions) {
      if (region.isActive) {
        [occlusions addObject:[NSValue valueWithCGRect:region.frame]];
      }
    }
    return [self isFoldableGeometryWithSafeAreaInsets:window.safeAreaInsets
                                           windowSize:window.bounds.size
                                     activeOcclusions:occlusions];
  }
  return NO;
}

+ (nullable UIWindow *)activeWindow {
  NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
      continue;
    }
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    [windows addObjectsFromArray:windowScene.windows];
  }
  for (UIWindow *window in windows) {
    if (window.isKeyWindow) {
      return window;
    }
  }
  return windows.firstObject;
}

+ (BOOL)foldableByModel {
  static BOOL foldable = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *identifier = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding] ?: @"";
#if TARGET_OS_SIMULATOR
    NSString *simulatorModelIdentifier = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
    foldable = [self isFoldableWithIdentifier:identifier
                     simulatorModelIdentifier:simulatorModelIdentifier
                                 isSimulator:YES];
#else
    foldable = [self isFoldableWithIdentifier:identifier simulatorModelIdentifier:nil isSimulator:NO];
#endif
  });
  return foldable;
}

+ (BOOL)isFoldableWithIdentifier:(NSString *)identifier
         simulatorModelIdentifier:(NSString *)simulatorModelIdentifier
                     isSimulator:(BOOL)isSimulator {
  // Simulator 名称可被修改，因此只接受机型标识符这一个模拟器信号。
  if (isSimulator) {
    return [simulatorModelIdentifier isEqualToString:@"iPhone19,4"];
  }
  return [identifier isEqualToString:@"iPhone19,4"];
}

+ (BOOL)isSideControlAreaWithFrame:(CGRect)frame windowSize:(CGSize)windowSize isActive:(BOOL)isActive {
  if (!isActive || windowSize.width <= 1 || windowSize.height <= 1) {
    return NO;
  }
  if (frame.size.width <= 0 || frame.size.height <= frame.size.width) {
    return NO;
  }
  // 侧边状态区是窄条；接近窗口宽度一半的遮挡区一定不是侧边控件。
  if (frame.size.width > windowSize.width * 0.3) {
    return NO;
  }
  return CGRectGetMinX(frame) <= 1 || CGRectGetMaxX(frame) >= windowSize.width - 1;
}

+ (BOOL)isFoldableGeometryWithSafeAreaInsets:(UIEdgeInsets)safeAreaInsets
                                  windowSize:(CGSize)windowSize
                            activeOcclusions:(NSArray<NSValue *> *)activeOcclusions {
  BOOL hasSingleSidedInset = (safeAreaInsets.left > 0) != (safeAreaInsets.right > 0);
  if (!hasSingleSidedInset) {
    return NO;
  }
  for (NSValue *value in activeOcclusions) {
    if ([self isSideControlAreaWithFrame:value.CGRectValue windowSize:windowSize isActive:YES]) {
      return YES;
    }
  }
  return NO;
}

@end

@implementation NEAdaptiveColumnGeometry

+ (BOOL)isDetailColumnWithFrameInWindow:(CGRect)frameInWindow
                           windowWidth:(CGFloat)windowWidth
                       safeAreaInsets:(UIEdgeInsets)safeAreaInsets {
  if (windowWidth <= 1 || frameInWindow.size.width <= 0 || frameInWindow.size.height <= 0) {
    return NO;
  }
  return CGRectGetMinX(frameInWindow) > safeAreaInsets.left + 1;
}

@end

CGFloat NEUIKitStatusBarHeight(void) {
  // 工程最低支持 iOS 15：统一走当前活跃场景的 statusBarManager，
  UIWindow *window = UIWindow.ne_activeKeyWindow;
  CGFloat height = window.windowScene.statusBarManager.statusBarFrame.size.height;
  if (height < 6 && window && ![NEAdaptiveDeviceGate adaptiveHostActive]) {
    // iOS 27 冷启动早期 statusBarManager 可能短暂报 0；此时 key window 的顶部安全区
    // 已经是真实状态栏高度。不回退会让页面在 viewDidLoad 把「44」永久写进约束，
    // 表现为标题/内容顶进状态栏。
    height = window.safeAreaInsets.top;
  }
  return height < 6 ? 0 : height;
}

CGFloat NEUIKitNavigationAndStatusHeight(void) {
  return 44.0 + NEUIKitStatusBarHeight();
}

CGFloat NEUIKitStatusBarHeightForView(UIView *view) {
  CGFloat height = NEUIKitStatusBarHeight();
  if (height >= 6 || !view) {
    return height;
  }
  if ([NEAdaptiveDeviceGate adaptiveHostActive]) {
    return height;
  }
  CGFloat safeTop = view.safeAreaInsets.top;
  return safeTop >= 6 ? safeTop : height;
}

CGFloat NEUIKitNavigationAndStatusHeightForView(UIView *view) {
  return 44.0 + NEUIKitStatusBarHeightForView(view);
}

@implementation UIViewController (NENavigationBarMetrics)

- (void)ne_refreshNavigationBarHeightIfNeeded {
  if (![self respondsToSelector:@selector(ne_navigationBarHeight)] ||
      ![self respondsToSelector:@selector(ne_applyNavigationBarHeight:)]) {
    return;
  }
  id<NENavigationBarHeightProviding> provider = (id<NENavigationBarHeightProviding>)self;
  CGFloat height = [provider ne_navigationBarHeight];
  if (height <= 0) {
    return;
  }
  [provider ne_applyNavigationBarHeight:height];
}

@end

CGFloat NEUIKitAdaptiveNavigationAndStatusHeight(void) {
  CGFloat extra = NEAdaptiveDeviceGate.adaptiveHostActive ? 2.0 : 0.0;
  return NEUIKitNavigationAndStatusHeight() + extra;
}

