// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager.h"

NS_ASSUME_NONNULL_BEGIN

static inline CGPoint NEKeyboardManagerCGPointInvalidValue(void) {
  return (CGPoint){CGFLOAT_MAX, CGFLOAT_MAX};
}

@interface NEWeakObjectContainer : NSObject

@property (nonatomic, weak, nullable) id object;
- (instancetype)initWithObject:(nullable id)object;

@end

@interface NEKeyboardManager (Internal)

@property (nonatomic, strong, readonly) UITapGestureRecognizer *resignFirstResponderGesture;

- (NSArray<UIView *> * _Nullable)responderViews;
- (BOOL)privateIsEnabled;
- (BOOL)privateIsEnableAutoToolbar;
- (BOOL)privateShouldResignOnTouchOutside;
- (nullable UIWindow *)keyWindow;

@end

NS_ASSUME_NONNULL_END
