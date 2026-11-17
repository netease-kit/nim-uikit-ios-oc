// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseChatMessageTipCell.h"
#import "ChatUIConfig.h"
#import "ChatCellConstantValue.h"
#import "MessageContentModel.h"
#import "MessageTipsModel.h"

@implementation NEBaseChatMessageTipCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.timeTextSize];
        _timeLabel.textColor = [ChatUIConfig shared].messageProperties.timeTextColor;
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.accessibilityIdentifier = @"id.messageTipText";
    }
    return _timeLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.timeTextSize];
        _contentLabel.textColor = [ChatUIConfig shared].messageProperties.timeTextColor;
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.numberOfLines = 0;
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabel.accessibilityIdentifier = @"id.messageTipText";
    }
    return _contentLabel;
}

- (void)commonUI {
    [self.contentView addSubview:self.timeLabel];
    self.timeLabelHeightAnchor = [self.timeLabel.heightAnchor constraintEqualToConstant:22];
    self.timeLabelHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0],
        [self.timeLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
        [self.timeLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16],
    ]];

    [self.contentView addSubview:self.contentLabel];
    self.contentLabelCenterYAnchor = [self.contentLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor];
    self.contentLabelCenterYAnchor.active = YES;
    self.contentWidthAnchor = [self.contentLabel.widthAnchor constraintEqualToConstant:chat_content_maxW()];
    self.contentWidthAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    ]];
}

- (void)setModel:(MessageTipsModel *)model {
    self.contentWidthAnchor.constant = model.viewport ? model.viewport.maximumBubbleWidth : chat_content_maxW();
    if (model.timeContent.length > 0) {
        self.timeLabelHeightAnchor.constant = chat_timeCellH;
        self.contentLabelCenterYAnchor.constant = chat_timeCellH / 2;
        self.timeLabel.text = model.timeContent;
        self.timeLabel.hidden = NO;
    } else {
        self.timeLabelHeightAnchor.constant = 0;
        self.contentLabelCenterYAnchor.constant = 0;
        self.timeLabel.text = @"";
        self.timeLabel.hidden = YES;
    }
    self.contentLabel.text = model.text;
}

@end
