// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

NS_ASSUME_NONNULL_BEGIN

/// 通讯录模块 ViewController 基类
@interface NEContactBaseViewController : UIViewController <UIGestureRecognizerDelegate>

@property(nonatomic, assign) CGFloat topConstant;

/// 自定义导航栏高度布局约束
@property(nonatomic, strong, nullable) NSLayoutConstraint *navigationViewHeightAnchor;

/// 自定义导航栏
@property(nonatomic, strong, readonly) NENavigationView *navigationView;

@property(nonatomic, strong) NEEmptyDataView *emptyView;

- (void)setupBackUI;
- (void)backEvent;
- (void)appEnterBackground;
- (void)toSetting;

@end

NS_ASSUME_NONNULL_END
