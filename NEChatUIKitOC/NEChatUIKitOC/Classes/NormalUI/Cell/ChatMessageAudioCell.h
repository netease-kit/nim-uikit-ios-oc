// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NormalChatMessageBaseCell.h"
#import "MessageAudioModel.h"
#import "ChatCellConstantValue.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageAudioCell : NormalChatMessageBaseCell <ChatAudioCellProtocol>

@property (nonatomic, copy, nullable) NSString *messageId;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, strong) UIImageView *audioImageViewLeft;
@property (nonatomic, strong) UILabel *timeLabelLeft;
@property (nonatomic, strong) UIView *audioBodyBackgroundViewLeft;
@property (nonatomic, strong) UILabel *contentLabelLeft;
@property (nonatomic, strong) UIView *backViewLeft;
@property (nonatomic, strong) UIImageView *audioImageViewRight;
@property (nonatomic, strong) UILabel *timeLabelRight;
@property (nonatomic, strong) UIView *audioBodyBackgroundViewRight;
@property (nonatomic, strong) UILabel *contentLabelRight;
@property (nonatomic, strong) UIView *backViewRight;

- (void)startAnimation:(BOOL)byRight;
- (void)stopAnimation:(BOOL)byRight;

@end

NS_ASSUME_NONNULL_END
