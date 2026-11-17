// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#ifndef NEAdaptiveUIKitOC_h
#define NEAdaptiveUIKitOC_h

// Geometry / policy
#import "NEAdaptiveLayoutTypes.h"
#import "NEAdaptiveLayoutPolicy.h"
#import "NEAdaptiveShellConfiguration.h"

// Rail navigation actions
#import "NEAdaptiveRailNavigation.h"

// Window facts
#import "NEAdaptiveWindowContext.h"

// Conversation opening contract
#import "NEConversationOpenIntent.h"
#import "NEConversationNavigationCoordinator.h"

// Stable chat detail host
#import "NEChatDetailHostController.h"

// Adaptive shell
#import "NEAdaptiveShellViewController.h"

// 列内底部弹窗基类不在本组件内：它要被 `NECustomActionSheetController` 等基础层弹窗继承，
// 而本组件保持零依赖，因此基类放在 `NEBaseUIKitOC`（`NEAdaptiveBottomSheetController.h`），
// 双方只通过通知名 `NEAdaptiveOverlayDidPresent` / `NEAdaptiveOverlayDidDismiss` 协作。

#endif /* NEAdaptiveUIKitOC_h */
