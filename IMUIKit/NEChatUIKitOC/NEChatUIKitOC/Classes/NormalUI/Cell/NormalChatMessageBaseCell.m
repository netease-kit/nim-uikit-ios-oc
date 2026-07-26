// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalChatMessageBaseCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NSString+NECommon.h>
#import "NEEmotionTool.h"

@implementation NormalChatMessageBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _replyViewHeight = 24;
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UIView *)replyViewLeft {
    if (!_replyViewLeft) {
        _replyViewLeft = [[UIView alloc] init];
        _replyViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _replyViewLeft.backgroundColor = UIColor.clearColor;
        [_replyViewLeft addSubview:self.replyLabelLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.replyLabelLeft.leadingAnchor constraintEqualToAnchor:_replyViewLeft.leadingAnchor constant:0],
            [self.replyLabelLeft.topAnchor constraintEqualToAnchor:_replyViewLeft.topAnchor constant:chat_content_margin],
            [self.replyLabelLeft.trailingAnchor constraintEqualToAnchor:_replyViewLeft.trailingAnchor constant:0],
            [self.replyLabelLeft.heightAnchor constraintEqualToConstant:16.0],
        ]];
    }
    return _replyViewLeft;
}

- (UILabel *)replyLabelLeft {
    if (!_replyLabelLeft) {
        _replyLabelLeft = [[UILabel alloc] init];
        _replyLabelLeft.font = [UIFont systemFontOfSize:13];
        _replyLabelLeft.textColor = [UIColor ne_colorWithHexString:@"#929299"];
        _replyLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _replyLabelLeft.accessibilityIdentifier = @"id.messageReply";
    }
    return _replyLabelLeft;
}

- (UIView *)replyViewRight {
    if (!_replyViewRight) {
        _replyViewRight = [[UIView alloc] init];
        _replyViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _replyViewRight.backgroundColor = UIColor.clearColor;
        [_replyViewRight addSubview:self.replyLabelRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.replyLabelRight.leadingAnchor constraintEqualToAnchor:_replyViewRight.leadingAnchor constant:0],
            [self.replyLabelRight.topAnchor constraintEqualToAnchor:_replyViewRight.topAnchor constant:chat_content_margin],
            [self.replyLabelRight.trailingAnchor constraintEqualToAnchor:_replyViewRight.trailingAnchor constant:0],
            [self.replyLabelRight.heightAnchor constraintEqualToConstant:16.0],
        ]];
    }
    return _replyViewRight;
}

- (UILabel *)replyLabelRight {
    if (!_replyLabelRight) {
        _replyLabelRight = [[UILabel alloc] init];
        _replyLabelRight.font = [UIFont systemFontOfSize:13];
        _replyLabelRight.textColor = [UIColor ne_colorWithHexString:@"#929299"];
        _replyLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _replyLabelRight.accessibilityIdentifier = @"id.messageReply";
    }
    return _replyLabelRight;
}

- (void)commonUI {
    [self commonUIRight];
    [self commonUILeft];
}

- (void)commonUILeft {
    [self.bubbleImageLeft addSubview:self.replyViewLeft];
    self.replyViewLeftHeightAnchor = [self.replyViewLeft.heightAnchor constraintEqualToConstant:self.replyViewHeight];
    self.replyViewLeftHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.replyViewLeft.leadingAnchor constraintEqualToAnchor:self.bubbleImageLeft.leadingAnchor constant:chat_content_margin],
        [self.replyViewLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor constant:0],
        [self.replyViewLeft.trailingAnchor constraintEqualToAnchor:self.bubbleImageLeft.trailingAnchor constant:-chat_content_margin],
    ]];
}

- (void)commonUIRight {
    [self.bubbleImageRight addSubview:self.replyViewRight];
    self.replyViewRightHeightAnchor = [self.replyViewRight.heightAnchor constraintEqualToConstant:self.replyViewHeight];
    self.replyViewRightHeightAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.replyViewRight.leadingAnchor constraintEqualToAnchor:self.bubbleImageRight.leadingAnchor constant:chat_content_margin],
        [self.replyViewRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor constant:0],
        [self.replyViewRight.trailingAnchor constraintEqualToAnchor:self.bubbleImageRight.trailingAnchor constant:-chat_content_margin],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.replyViewLeft.hidden = showRight;
    self.replyLabelLeft.hidden = showRight;
    self.replyViewRight.hidden = !showRight;
    self.replyLabelRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    UILabel *replyLabel = isSend ? self.replyLabelRight : self.replyLabelLeft;
    UIView *replyView = isSend ? self.replyViewRight : self.replyViewLeft;
    NSLayoutConstraint *replyViewHeightAnchor = isSend ? self.replyViewRightHeightAnchor : self.replyViewLeftHeightAnchor;

    if (!model.isRevoked && model.replyText.length > 0 && replyLabel.font) {
        NSString *text = model.replyText;
        if (![text isEqualToString:chatLocalizable(@"message_not_found")]) {
            text = [@"| " stringByAppendingString:text];
        }

        replyLabel.attributedText = [NEEmotionTool getAttWithStr:text font:replyLabel.font color:replyLabel.textColor offset:CGPointMake(0, -4)];
        replyLabel.accessibilityValue = text;

        if (replyLabel.attributedText) {
            CGSize textSize = [NSAttributedString ne_getRealLabelSize:replyLabel.attributedText font:replyLabel.font size:CGSizeMake(chat_text_maxW(), CGFLOAT_MAX) numberOfLines:0];

            if ([model isKindOfClass:[MessageTextModel class]]) {
                model.contentSize = CGSizeMake(MAX(textSize.width, model.textWidth) + chat_content_margin * 2, model.contentSize.height);
            } else {
                model.contentSize = CGSizeMake(MAX(textSize.width + chat_content_margin * 2, model.contentSize.width), model.contentSize.height);
            }

            replyViewHeightAnchor.constant = self.replyViewHeight;
            replyLabel.hidden = NO;
            replyView.hidden = NO;
        }
    } else {
        replyLabel.text = nil;
        replyViewHeightAnchor.constant = 0;
        replyLabel.hidden = YES;
        replyView.hidden = YES;
    }

    [super setModel:model isSend:isSend];
}

@end
