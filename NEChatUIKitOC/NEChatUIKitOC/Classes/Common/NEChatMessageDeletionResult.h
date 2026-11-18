// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEChatMessageDeletionResult : NSObject

@property(nonatomic, copy, readonly) NSArray<NSNumber *> *deletedIndexes;
@property(nonatomic, copy, readonly) NSArray<NSNumber *> *reloadedIndexes;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
