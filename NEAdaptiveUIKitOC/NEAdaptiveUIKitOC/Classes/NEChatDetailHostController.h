// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 稳定持有聊天导航栈的父容器。
///
@interface NEChatDetailHostController : UIViewController

/// 被稳定持有的聊天导航栈。
@property (nonatomic, strong, readonly) UINavigationController *navigationControllerContent;

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
    NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
