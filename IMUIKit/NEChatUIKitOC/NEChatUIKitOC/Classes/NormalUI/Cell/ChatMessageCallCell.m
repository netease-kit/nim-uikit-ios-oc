// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageCallCell.h"

@implementation ChatMessageCallCell

- (UILabel *)contentLabelLeft {
    if (!_contentLabelLeft) {
        _contentLabelLeft = [[UILabel alloc] init];
        _contentLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft.enabled = NO;
        _contentLabelLeft.numberOfLines = 0;
        _contentLabelLeft.userInteractionEnabled = NO;
        _contentLabelLeft.font = self.messageTextFont;
        _contentLabelLeft.textAlignment = NSTextAlignmentCenter;
        _contentLabelLeft.backgroundColor = UIColor.clearColor;
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
        _contentLabelRight.backgroundColor = UIColor.clearColor;
        _contentLabelRight.accessibilityIdentifier = @"id.chatMessageCallText";
    }
    return _contentLabelRight;
}

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.contentLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-chat_content_margin],
        [self.contentLabelLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:chat_content_margin],
        [self.contentLabelLeft.topAnchor constraintEqualToAnchor:self.replyViewLeft.topAnchor constant:0],
        [self.contentLabelLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:0],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.contentLabelRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-chat_content_margin],
        [self.contentLabelRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:chat_content_margin],
        [self.contentLabelRight.topAnchor constraintEqualToAnchor:self.replyViewRight.topAnchor constant:0],
        [self.contentLabelRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:0],
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
    if ([model isKindOfClass:[MessageCallRecordModel class]]) {
        UILabel *contentLabel = isSend ? self.contentLabelRight : self.contentLabelLeft;
        contentLabel.attributedText = ((MessageCallRecordModel *)model).callRecordAttributeStr;
    }
}

@end
