// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (NSLayoutConstraint)

- (NSArray<NSLayoutConstraint *> *)ne_constraintsAnchorFromView:(UIView *)fromView
                                                         toView:(UIView *)toView;

@end

NS_ASSUME_NONNULL_END
