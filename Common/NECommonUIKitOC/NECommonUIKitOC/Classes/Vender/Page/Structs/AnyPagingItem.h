// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEPagingItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface AnyPagingItem : NSObject <NEPagingItem, NSCopying>

@property (nonatomic, strong, readonly) id<NEPagingItem> base;

- (instancetype)initWithBase:(id<NEPagingItem>)base;

@end

NS_ASSUME_NONNULL_END
