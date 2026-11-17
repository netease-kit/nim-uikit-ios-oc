// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 单条消息展示面的几何。
///
/// `MessageContentModel.applyViewport:` 使用同一份宽度，不必再读屏幕常量。
@interface NEChatViewport : NSObject

@property (nonatomic, assign, readonly) CGFloat contentWidth;
@property (nonatomic, assign, readonly) CGFloat maximumBubbleWidth;
@property (nonatomic, assign, readonly) CGFloat maximumTextWidth;
@property (nonatomic, assign, readonly) CGFloat maximumAudioWidth;

- (instancetype)initWithContentWidth:(CGFloat)contentWidth NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
