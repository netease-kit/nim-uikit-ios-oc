// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIWindow+NEActiveKeyWindow.h"

static NSInteger NEActivationRank(UISceneActivationState state) {
  switch (state) {
    case UISceneActivationStateForegroundActive:
      return 0;
    case UISceneActivationStateForegroundInactive:
      return 1;
    case UISceneActivationStateBackground:
      return 2;
    case UISceneActivationStateUnattached:
      return 3;
  }
  return 4;
}

@implementation UIWindow (NEActiveKeyWindow)

+ (UIWindow *)ne_activeKeyWindow {
  NSMutableArray<UIWindowScene *> *scenes = [NSMutableArray array];
  for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
    if ([scene isKindOfClass:[UIWindowScene class]]) {
      [scenes addObject:(UIWindowScene *)scene];
    }
  }
  [scenes sortUsingComparator:^NSComparisonResult(UIWindowScene *lhs, UIWindowScene *rhs) {
    NSInteger left = NEActivationRank(lhs.activationState);
    NSInteger right = NEActivationRank(rhs.activationState);
    if (left == right) {
      return NSOrderedSame;
    }
    return left < right ? NSOrderedAscending : NSOrderedDescending;
  }];
  for (UIWindowScene *scene in scenes) {
    for (UIWindow *window in scene.windows) {
      if (window.isKeyWindow) {
        return window;
      }
    }
  }
  return scenes.firstObject.windows.firstObject;
}

@end
