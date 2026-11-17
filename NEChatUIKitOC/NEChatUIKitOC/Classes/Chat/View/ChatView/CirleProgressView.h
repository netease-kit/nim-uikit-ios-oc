// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CirleProgressView : UIView

/// 进度 0~1
@property (nonatomic, assign) float progress;
@property (nonatomic, strong) CAShapeLayer *borderLayer;
@property (nonatomic, strong) CAShapeLayer *sectorLayer;

- (void)drawCircleWithProgress:(float)progress;

@end

NS_ASSUME_NONNULL_END
