// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAnimatedControl.h"

NS_ASSUME_NONNULL_BEGIN

/// Interactive button that plays configured animation ranges for touch events.
@interface NEAnimatedButton : NEAnimatedControl

@property (nonatomic, copy, nullable) void (^performAction)(void);

- (void)setPlayRangeFromProgress:(CGFloat)fromProgress
                      toProgress:(CGFloat)toProgress
                           event:(UIControlEvents)event;
- (void)setPlayRangeFromMarker:(NSString *)fromName
                      toMarker:(NSString *)toName
                         event:(UIControlEvents)event;

@end

NS_ASSUME_NONNULL_END
