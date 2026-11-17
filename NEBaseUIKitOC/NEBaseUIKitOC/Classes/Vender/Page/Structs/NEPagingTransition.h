// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEPagingTransition : NSObject

@property (nonatomic, assign, readonly) CGPoint contentOffset;
@property (nonatomic, assign, readonly) CGFloat distance;

- (instancetype)initWithContentOffset:(CGPoint)contentOffset
                             distance:(CGFloat)distance;

@end

NS_ASSUME_NONNULL_END
