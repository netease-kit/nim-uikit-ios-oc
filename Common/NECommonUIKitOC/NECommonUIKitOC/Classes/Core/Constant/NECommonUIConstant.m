// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECommonUIConstant.h"
#import <NEChatKitOC/NECommonLoader.h>
#import "TabNavigationView.h"

NSString *const useSystemNav = @"useSystemNav";

static NECommonLoader *_coreLoader = nil;

NECommonLoader *coreLoader(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // 用模块内某个类定位 bundle（对齐 Swift: CommonLoader<TabNavigationView>()）
    _coreLoader = [[NECommonLoader alloc] initWithClass:[TabNavigationView class]];
  });
  return _coreLoader;
}

NSString *commonLocalizable(NSString *key) {
  return [coreLoader() localizable:key];
}