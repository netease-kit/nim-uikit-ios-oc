// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEKeyboardManager (Debug)

- (void)showLog:(NSString *)logString;
- (void)showLog:(NSString *)logString indentation:(NSInteger)indentation;

@end

NS_ASSUME_NONNULL_END
