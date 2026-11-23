// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAISearchManager.h"
#import "AIWordSearch/NEAISearchConstant.h"
#import "AIWordSearch/NEAIWordSearchViewController.h"
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/ChatKitClient.h>
#import <NEChatKit/OperationItem.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/ViewControllerExtension.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import <NEBaseUIKitOC/UIWindow+NEActiveKeyWindow.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/XKitServiceManager.h>

@implementation NEAISearchManager

+ (instancetype)shared {
  static NEAISearchManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEAISearchManager alloc] initPrivate];
  });
  return instance;
}

- (instancetype)init {
  return [NEAISearchManager shared];
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _serviceName = NEAISearchPlugin ?: @"";
    // Keep the public plugin metadata aligned with the Swift implementation.
    _versionName = @"1.0.0";
    _appKey = [[IMKitClient instance] appKey] ?: @"";
  }
  return self;
}

- (void)setupInit {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [[XKitServiceManager getInstance] registerService:self.serviceName service:self];
    [[IMKitPluginManager shared] registerPlugin:self.serviceName plugin:self];
    NSString *version = [ChatKitClient componentVersionForBundle:[NSBundle bundleForClass:self.class]
                                                          fallback:@""];
    [[ChatKitClient shared] buryDataPoints:@"AISearchKitOC" version:version];
  });
}

- (nullable OperationItem *)registerPlugin:(NSString *)text {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = NEAISearchLocalizable(@"operation_ai_word_search");
  item.image = NEAISearchImageNamed(@"op_ai_word");
  item.type = OperationTypePlugin;

  NSString *selectedText = [text copy] ?: @"";
  item.onClick = ^(UIViewController * _Nullable viewController) {
    if (!viewController) {
      return;
    }

    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      [viewController showToast:commonLocalizable(@"network_error")];
      return;
    }

    if (selectedText.length == 0) {
      [viewController showToast:NEAISearchLocalizable(@"not_supported")];
      return;
    }

    NEAIWordSearchViewController *viewControllerToPresent =
        [[NEAIWordSearchViewController alloc] initWithSearchText:selectedText];
    UIWindow *window = viewController.isViewLoaded ? viewController.view.window : nil;
    UIView *hostView = viewController.isViewLoaded ? viewController.view : nil;
    UINavigationController *navigation = viewController.navigationController;
    BOOL adaptiveHost = [NEAdaptiveDeviceGate adaptiveHostActive];
    BOOL hostIsColumn = NO;
    if (adaptiveHost && hostView && window) {
      CGFloat hostWidth = CGRectGetWidth(hostView.bounds);
      CGFloat windowWidth = CGRectGetWidth(window.bounds);
      hostIsColumn = (hostWidth < windowWidth - 20) ||
                     (hostWidth >= windowWidth - 1 && window.safeAreaInsets.right > 0);
    }
    if (hostIsColumn) {
      [self presentInColumn:viewControllerToPresent host:viewController];
      return;
    }
    if (adaptiveHost && window && CGRectGetWidth(window.bounds) >= 700) {
      // 这时要从控制器树里找到"右列导航容器"作为 presentation context，
      UINavigationController *columnNavigation = navigation;
      if (!columnNavigation || columnNavigation.view.window != window) {
        columnNavigation = [self adaptiveColumnNavigationFrom:viewController window:window];
      }
      if (columnNavigation) {
        viewControllerToPresent.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        columnNavigation.definesPresentationContext = YES;
        [columnNavigation presentViewController:viewControllerToPresent animated:YES completion:nil];
        return;
      }
    }
    if (navigation) {
      [viewController showBottomSheetInDetailColumn:viewControllerToPresent animated:YES completion:nil];
      return;
    }
    UIViewController *root = [UIWindow ne_activeKeyWindow].rootViewController;
    if (root) {
      [root presentViewController:viewControllerToPresent animated:YES completion:nil];
    }
  };
  return item;
}

/// 在控制器树里找"右列导航容器"：视图在窗口坐标里不从 0 开始、且宽度小于整窗。
- (nullable UINavigationController *)adaptiveColumnNavigationFrom:(UIViewController *)root
                                                          window:(UIWindow *)window {
  if (!root || !window) return nil;
  CGFloat windowWidth = CGRectGetWidth(window.bounds);
  NSMutableArray<UIViewController *> *queue = [NSMutableArray arrayWithObject:root];
  UINavigationController *best = nil;
  NSInteger guard = 0;
  while (queue.count > 0 && guard++ < 300) {
    UIViewController *vc = queue.firstObject;
    [queue removeObjectAtIndex:0];
    if ([vc isKindOfClass:[UINavigationController class]] && vc.isViewLoaded && vc.view.window == window) {
      CGRect frameInWindow = [vc.view convertRect:vc.view.bounds toView:window];
      CGFloat width = CGRectGetWidth(frameInWindow);
      if (width > 0 && width < windowWidth - 20 && CGRectGetMinX(frameInWindow) > 1 && !vc.view.hidden) {
        best = (UINavigationController *)vc;
      }
    }
    [queue addObjectsFromArray:vc.childViewControllers];
  }
  return best;
}

/// 展开双栏：把 AI 弹窗作为聊天页的子控制器嵌入内容列，
- (void)presentInColumn:(NEAIWordSearchViewController *)controller host:(UIViewController *)host {
  UIView *hostView = host.view;
  if (!hostView) {
    return;
  }
  CGFloat windowWidth = hostView.window ? CGRectGetWidth(hostView.window.bounds) : CGRectGetWidth(hostView.bounds);
  BOOL isFullWindow = CGRectGetWidth(hostView.bounds) >= windowWidth - 1;
  CGFloat railInset = isFullWindow ? MAX(0, hostView.window.safeAreaInsets.right) : 0;
  CGFloat columnWidth = MAX(0, CGRectGetWidth(hostView.bounds) - railInset);

  UIControl *dim = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, columnWidth, CGRectGetHeight(hostView.bounds))];
  dim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
  dim.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  dim.accessibilityIdentifier = @"ai.word.search.column.dim";

  controller.isEmbeddedInColumn = YES;
  controller.columnDimView = dim;
  controller.view.accessibilityIdentifier = @"ai.word.search.column.v4";
  controller.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  controller.cancelButton.hidden = YES;

  [host addChildViewController:controller];
  [hostView addSubview:dim];
  [hostView addSubview:controller.view];
  [controller didMoveToParentViewController:host];

  CGFloat height = MIN(406.0, CGRectGetHeight(hostView.bounds));
  controller.view.frame = CGRectMake(0, CGRectGetHeight(hostView.bounds) - height, columnWidth, height);
  [controller.view setNeedsLayout];
  [controller.view layoutIfNeeded];

  __weak NEAIWordSearchViewController *weakController = controller;
  __weak UIControl *weakDim = dim;
  void (^dismiss)(void) = ^{
    NEAIWordSearchViewController *strongController = weakController;
    strongController.columnDismissHandler = nil;
    [strongController willMoveToParentViewController:nil];
    [strongController.view removeFromSuperview];
    [strongController removeFromParentViewController];
    [weakDim removeFromSuperview];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptiveOverlayDidDismiss" object:nil];
  };
  controller.columnDismissHandler = dismiss;
  [dim addAction:[UIAction actionWithHandler:^(__unused UIAction *action) {
    dismiss();
  }]
      forControlEvents:UIControlEventTouchUpInside];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptiveOverlayDidPresent"
                                                      object:nil
                                                    userInfo:@{@"dismiss": dismiss}];
}

@end
