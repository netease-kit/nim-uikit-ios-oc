// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEActionSheetPresentationController : NSObject <UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate>

/// 点击空白区域是否收回弹出视图，默认 YES
@property (nonatomic, assign) BOOL dismissOnTouchOutside;

/// 响应驱动消失手势的距离，默认 30
@property (nonatomic, assign) CGFloat interactiveDismissalDistance;

/// dismiss 百分比驱动
@property (nonatomic, strong, nullable) UIPercentDrivenInteractiveTransition *dismissAnimator;

@end

NS_ASSUME_NONNULL_END
