// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PagingDirectionKind) {
  PagingDirectionKindReverse = -1,
  PagingDirectionKindNone = 0,
  PagingDirectionKindForward = 1,
};

@interface PagingDirection : NSObject <NSCopying>

@property (nonatomic, assign, readonly) PagingDirectionKind kind;
@property (nonatomic, assign, readonly, getter=isSibling) BOOL sibling;

+ (instancetype)reverseWithSibling:(BOOL)sibling;
+ (instancetype)forwardWithSibling:(BOOL)sibling;
+ (instancetype)noneDirection;

@end

NS_ASSUME_NONNULL_END
