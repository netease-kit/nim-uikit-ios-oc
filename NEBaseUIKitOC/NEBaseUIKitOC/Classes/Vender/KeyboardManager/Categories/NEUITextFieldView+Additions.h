// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEKeyboardManagerConstants.h"

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN const CGFloat kNEUseDefaultKeyboardDistance;

@interface UIView (NETextFieldViewAdditions)

@property (nonatomic, assign) CGFloat neKeyboardDistanceFromTextField;
@property (nonatomic, assign) BOOL neIgnoreSwitchingByNextPrevious;
@property (nonatomic, assign) NEEnableMode neEnableMode;
@property (nonatomic, assign) NEEnableMode neShouldResignOnTouchOutsideMode;

@end

NS_ASSUME_NONNULL_END
