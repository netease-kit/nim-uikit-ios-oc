// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NormalChatMessageBaseCell.h"
#import "MessageImageModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageImageCell : NormalChatMessageBaseCell

@property (nonatomic, strong) UIImageView *contentImageViewLeft;
@property (nonatomic, strong) UIImageView *contentImageViewRight;

- (void)setCustomCorner:(BOOL)hasReply;

@end

NS_ASSUME_NONNULL_END
