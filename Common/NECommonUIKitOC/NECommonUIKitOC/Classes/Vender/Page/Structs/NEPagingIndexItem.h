// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEPagingItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEPagingIndexItem : NSObject <NEPagingItem, NSCopying>

@property (nonatomic, assign, readonly) NSInteger index;
@property (nonatomic, copy, readonly) NSString *title;

- (instancetype)initWithIndex:(NSInteger)index title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
