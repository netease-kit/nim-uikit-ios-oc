// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Objective-C compatible animation keypath wrapper.
@interface NECompatibleAnimationKeypath : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithKeypath:(NSString *)keypath NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithKeys:(NSArray<NSString *> *)keys NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
