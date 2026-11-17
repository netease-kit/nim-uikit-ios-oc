// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatViewport.h"

#import "ChatCellConstantValue.h"

@implementation NEChatViewport

- (instancetype)initWithContentWidth:(CGFloat)contentWidth {
  self = [super init];
  if (self) {
    CGFloat width = (isfinite(contentWidth) && contentWidth > 0) ? contentWidth : chat_content_maxW();
    _contentWidth = width;
    _maximumBubbleWidth = MAX(32, width - 156);
    _maximumTextWidth = MAX(16, _maximumBubbleWidth - 2 * chat_content_margin);
    _maximumAudioWidth = MIN(_maximumBubbleWidth, width <= 325 ? 230 : 265);
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<NEChatViewport: content=%g bubble=%g text=%g audio=%g>",
                                    _contentWidth, _maximumBubbleWidth, _maximumTextWidth,
                                    _maximumAudioWidth];
}

@end
