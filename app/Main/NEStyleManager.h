// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// UI 风格管理器（对齐 Swift NEStyleManager）
/// Normal = 1, Fun = 2
@interface NEStyleManager : NSObject

+ (instancetype)instance;

- (BOOL)isNormalStyle;
- (void)setNormalStyle;
- (void)setFunStyle;

@end

NS_ASSUME_NONNULL_END
