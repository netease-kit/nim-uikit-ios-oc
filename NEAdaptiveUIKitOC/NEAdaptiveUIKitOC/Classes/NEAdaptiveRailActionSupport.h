// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEAdaptiveActionInvocation : NSObject

+ (void)invokeSelector:(SEL)selector onTarget:(nullable id)target sender:(nullable id)sender;
+ (void)forwardControl:(UIControl *)control;

@end

@interface NEAdaptiveRailTitle : NSObject

+ (void)splitTitle:(nullable NSString *)title
              text:(NSString *_Nullable *_Nullable)text
             badge:(NSString *_Nullable *_Nullable)badge;

@end

NS_ASSUME_NONNULL_END
