// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NEInvocation;

NS_ASSUME_NONNULL_BEGIN

@interface NEBarButtonItem : UIBarButtonItem

@property (nonatomic, assign) BOOL isSystemItem;
@property (nonatomic, strong, nullable) NEInvocation *invocation;

- (void)setTarget:(nullable id)target action:(nullable SEL)action;

@end

NS_ASSUME_NONNULL_END
