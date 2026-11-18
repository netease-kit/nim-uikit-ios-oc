// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEAutoToolbarManageBehaviour) {
  NEAutoToolbarManageBehaviourBySubviews = 0,
  NEAutoToolbarManageBehaviourByTag = 1,
  NEAutoToolbarManageBehaviourByPosition = 2,
};

typedef NS_ENUM(NSInteger, NEPreviousNextDisplayMode) {
  NEPreviousNextDisplayModeDefault = 0,
  NEPreviousNextDisplayModeAlwaysHide = 1,
  NEPreviousNextDisplayModeAlwaysShow = 2,
};

typedef NS_ENUM(NSInteger, NEEnableMode) {
  NEEnableModeDefault = 0,
  NEEnableModeEnabled = 1,
  NEEnableModeDisabled = 2,
};

NS_ASSUME_NONNULL_END
