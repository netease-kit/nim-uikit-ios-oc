// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBarButtonItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NETitleBarButtonItem : NEBarButtonItem

@property (nonatomic, strong, nullable) UIFont *titleFont;
@property (nonatomic, strong, nullable) UIColor *titleColor;
@property (nonatomic, strong, nullable) UIColor *selectableTitleColor;

- (instancetype)initWithTitle:(nullable NSString *)title;

@end

NS_ASSUME_NONNULL_END
