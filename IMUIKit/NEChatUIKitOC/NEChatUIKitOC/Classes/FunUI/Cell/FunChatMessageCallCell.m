// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageCallCell.h"
#import "ChatCellConstantValue.h"
#import "MessageCallRecordModel.h"

@implementation FunChatMessageCallCell

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.contentLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-chat_content_margin],
        [self.contentLabelLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:chat_content_margin + self.funMargin],
        [self.contentLabelLeft.centerYAnchor constraintEqualToAnchor:self.bubbleImageLeft.centerYAnchor],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.contentLabelRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-(chat_content_margin + self.funMargin)],
        [self.contentLabelRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:chat_content_margin],
        [self.contentLabelRight.centerYAnchor constraintEqualToAnchor:self.bubbleImageRight.centerYAnchor],
    ]];
    [self.activityView removeFromSuperview];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.contentLabelLeft.hidden = showRight;
    self.contentLabelRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    UILabel *contentLabel = isSend ? self.contentLabelRight : self.contentLabelLeft;
    if ([model isKindOfClass:[MessageCallRecordModel class]]) {
        contentLabel.attributedText = ((MessageCallRecordModel *)model).callRecordAttributeStr;
    }
}

#pragma mark - Lazy Load

- (UILabel *)contentLabelLeft {
    if (!_contentLabelLeft) {
        _contentLabelLeft = [[UILabel alloc] init];
        _contentLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft.enabled = NO;
        _contentLabelLeft.numberOfLines = 0;
        _contentLabelLeft.userInteractionEnabled = NO;
        _contentLabelLeft.font = self.messageTextFont;
        _contentLabelLeft.textAlignment = NSTextAlignmentCenter;
        _contentLabelLeft.backgroundColor = [UIColor clearColor];
        _contentLabelLeft.accessibilityIdentifier = @"id.chatMessageCallText";
    }
    return _contentLabelLeft;
}

- (UILabel *)contentLabelRight {
    if (!_contentLabelRight) {
        _contentLabelRight = [[UILabel alloc] init];
        _contentLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelRight.enabled = NO;
        _contentLabelRight.numberOfLines = 0;
        _contentLabelRight.userInteractionEnabled = NO;
        _contentLabelRight.font = self.messageTextFont;
        _contentLabelRight.textAlignment = NSTextAlignmentCenter;
        _contentLabelRight.backgroundColor = [UIColor clearColor];
        _contentLabelRight.accessibilityIdentifier = @"id.chatMessageCallText";
    }
    return _contentLabelRight;
}

@end
