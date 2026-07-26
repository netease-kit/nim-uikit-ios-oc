// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageAIStreamTextCell.h"
#import <NEChatKit/NSString+NECommon.h>
#import "UIImage+Chat.h"
#import <NEChatKit/NEChatKitOC.h>
#import "ChatCellConstantValue.h"
#import "NEChatUIConstant.h"

@implementation FunChatMessageAIStreamTextCell

- (void)commonUILeft {
    [super commonUILeft];
    self.contentLabelLeft.font = nil;

    if (IMKitConfigCenter.shared.enableAIStream) {
        [self.bubbleImageLeft addSubview:self.loadingViewLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.loadingViewLeft.leftAnchor constraintEqualToAnchor:self.contentLabelLeft.leftAnchor constant:4],
            [self.loadingViewLeft.topAnchor constraintEqualToAnchor:self.contentLabelLeft.topAnchor],
            [self.loadingViewLeft.widthAnchor constraintEqualToConstant:24],
            [self.loadingViewLeft.heightAnchor constraintEqualToConstant:24],
        ]];
    }

    [self.contentView addSubview:self.stopStreamButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.stopStreamButton.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:7],
        [self.stopStreamButton.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor],
        [self.stopStreamButton.widthAnchor constraintEqualToConstant:24],
        [self.stopStreamButton.heightAnchor constraintEqualToConstant:24],
    ]];

    [self.contentView addSubview:self.regenStreamButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.regenStreamButton.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:7],
        [self.regenStreamButton.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor],
        [self.regenStreamButton.widthAnchor constraintEqualToConstant:24],
        [self.regenStreamButton.heightAnchor constraintEqualToConstant:24],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    self.contentLabelRight.font = nil;
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.loadingViewLeft.hidden = showRight;
    self.stopStreamButton.hidden = showRight;
    self.regenStreamButton.hidden = showRight;
}

- (void)setSelect:(MessageContentModel *)model enableSelect:(BOOL)enableSelect {
    [super setSelect:model enableSelect:enableSelect];
    if (enableSelect) {
        NSInteger streamStatus = model.message.aiConfig.aiStreamStatus;
        self.selectedButton.hidden = (streamStatus == V2NIM_MESSAGE_AI_STREAM_STATUS_PLACEHOLDER ||
                                      streamStatus == V2NIM_MESSAGE_AI_STREAM_STATUS_STREAMING);
        self.stopStreamButton.hidden = YES;
        self.regenStreamButton.hidden = YES;
    }
}

- (CGSize)getTextSize:(NSAttributedString *)attributedText {
    return [NSAttributedString getRealTextViewSize:attributedText
                                              font:self.messageTextFont
                                           maxSize:self.contentModel.messageMaxSize];
}

- (void)stopStreamButtonAction {
    if ([self.delegate respondsToSelector:@selector(stopAIStreamMessage:model:)]) {
        [self.delegate stopAIStreamMessage:self model:self.contentModel];
    }
}

- (void)regenStreamButtonAction {
    if ([self.delegate respondsToSelector:@selector(regenAIStreamMessage:model:)]) {
        [self.delegate regenAIStreamMessage:self model:self.contentModel];
    }
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    NEChatTextView *contentLabel = isSend ? self.contentLabelRight : self.contentLabelLeft;

    if (IMKitConfigCenter.shared.enableAIStream &&
        model.message.aiConfig.aiStreamStatus == V2NIM_MESSAGE_AI_STREAM_STATUS_PLACEHOLDER) {
        contentLabel.hidden = YES;
        self.loadingViewLeft.hidden = NO;
        [self.loadingViewLeft play];
        self.stopStreamButton.hidden = ![model.message.threadReply.senderId isEqualToString:[IMKitClient instance].account];
        self.regenStreamButton.hidden = YES;
    } else {
        contentLabel.hidden = NO;
        self.loadingViewLeft.hidden = YES;
        [self.loadingViewLeft stop];

        NSString *myAccount = [IMKitClient instance].account;
        BOOL isMine = [model.message.threadReply.senderId isEqualToString:myAccount];
        self.stopStreamButton.hidden = !isMine ||
            model.message.aiConfig.aiStreamStatus != V2NIM_MESSAGE_AI_STREAM_STATUS_STREAMING;
        self.regenStreamButton.hidden = !isMine ||
            model.message.aiConfig.aiStreamStatus == V2NIM_MESSAGE_AI_STREAM_STATUS_STREAMING;
    }

    if (self.singleLeft) {
        self.loadingViewLeft.hidden = YES;
        self.stopStreamButton.hidden = YES;
        self.regenStreamButton.hidden = YES;
    }
}

#pragma mark - Lazy Load

- (NELottieAnimationView *)loadingViewLeft {
    if (!_loadingViewLeft) {
        _loadingViewLeft = [[NELottieAnimationView alloc] initWithName:@"ai_stream_loading_data" bundle:chatBundle()];
        _loadingViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _loadingViewLeft.loopMode = LottieLoopModeLoop;
        _loadingViewLeft.contentMode = UIViewContentModeScaleAspectFill;
        _loadingViewLeft.hidden = YES;
        _loadingViewLeft.accessibilityIdentifier = @"id.loadingView";
    }
    return _loadingViewLeft;
}

- (UIButton *)stopStreamButton {
    if (!_stopStreamButton) {
        _stopStreamButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _stopStreamButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_stopStreamButton setImage:[UIImage ne_imageNamed:@"fun_ai_stream_stop"] forState:UIControlStateNormal];
        _stopStreamButton.hidden = YES;
        [_stopStreamButton addTarget:self action:@selector(stopStreamButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _stopStreamButton.accessibilityIdentifier = @"id.stopStreamButton";
    }
    return _stopStreamButton;
}

- (UIButton *)regenStreamButton {
    if (!_regenStreamButton) {
        _regenStreamButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _regenStreamButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_regenStreamButton setImage:[UIImage ne_imageNamed:@"fun_ai_stream_regen"] forState:UIControlStateNormal];
        _regenStreamButton.hidden = YES;
        [_regenStreamButton addTarget:self action:@selector(regenStreamButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _regenStreamButton.accessibilityIdentifier = @"id.regenStreamButton";
    }
    return _regenStreamButton;
}

@end
