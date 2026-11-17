// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEKeyboardManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEKeyboardManager (Position)

@property (nonatomic, assign) CGFloat movedDistance;
@property (nonatomic, copy, nullable) void (^movedDistanceChanged)(CGFloat movedDistance);
@property (nonatomic, weak, nullable) UIScrollView *lastScrollView;
@property (nonatomic, assign) CGPoint startingContentOffset;
@property (nonatomic, assign) UIEdgeInsets startingScrollIndicatorInsets;
@property (nonatomic, assign) UIEdgeInsets startingContentInsets;
@property (nonatomic, assign) UIEdgeInsets startingTextViewContentInsets;
@property (nonatomic, assign) UIEdgeInsets startingTextViewScrollIndicatorInsets;
@property (nonatomic, assign) BOOL isTextViewContentInsetChanged;

- (void)optimizedAdjustPosition;
- (void)restorePosition;

@end

NS_ASSUME_NONNULL_END
