// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NELastReadPositionSnapshot;

/// Independent entry for jumping to the first message after the frozen read time.
@interface NEBaseChatLastReadPositionView : UIView

@property (nonatomic, strong, readonly) UIImageView *positionImageView;
@property (nonatomic, strong, readonly) UILabel *messageCountLabel;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIColor *accentColor;

- (void)updateWithSnapshot:(NELastReadPositionSnapshot *)snapshot locating:(BOOL)locating;

@end

NS_ASSUME_NONNULL_END
