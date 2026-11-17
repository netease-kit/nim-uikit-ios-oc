// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingItems;

@interface NEPagingDiff : NSObject

- (instancetype)initWithFromItems:(NEPagingItems *)fromItems
                           toItems:(NEPagingItems *)toItems;
- (NSArray<NSIndexPath *> *)addedIndexPaths;
- (NSArray<NSIndexPath *> *)removedIndexPaths;

@end

NS_ASSUME_NONNULL_END
