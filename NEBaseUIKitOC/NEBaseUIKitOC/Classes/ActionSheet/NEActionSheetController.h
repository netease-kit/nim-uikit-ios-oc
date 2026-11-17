// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 带导航栏的底部弹出视图
/// 待弹出的视图需要实现 preferredContentSize 来设置大小
@interface NEActionSheetController : UINavigationController

/// 点击空白区域是否收回弹出视图，默认 YES
@property (nonatomic, assign) BOOL dismissOnTouchOutside;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController;

@end

NS_ASSUME_NONNULL_END
