// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatNavigationView : NENavigationView

@property (nonatomic, strong) UIImageView *earImageView;

/// 设置听筒模式
- (void)setHandsetMode:(BOOL)ear;

@end

NS_ASSUME_NONNULL_END
