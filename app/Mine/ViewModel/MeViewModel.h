// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Swift MeViewModel
@interface MeViewModel : NSObject

/// 列表数据 — 每项为 @{ @"标题": @"图标名" }
@property (nonatomic, strong, readonly) NSArray<NSDictionary<NSString *, NSString *> *> *mineData;

- (void)getData;

@end

NS_ASSUME_NONNULL_END
