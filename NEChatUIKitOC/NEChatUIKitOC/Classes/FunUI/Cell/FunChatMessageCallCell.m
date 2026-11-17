// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageCallCell.h"
#import "ChatCellConstantValue.h"
#import "MessageCallRecordModel.h"

@interface FunChatMessageCallCell ()

@property (nonatomic, strong) UIView *callBodyBackgroundViewLeft;
@property (nonatomic, strong) UIView *callBodyBackgroundViewRight;

- (UIView *)makeCallBodyBackgroundView;
- (void)updateCallBodyBackgrounds;
- (void)updateCallBodyBackground:(UIView *)view displayed:(BOOL)displayed color:(UIColor *)color;

@end

@implementation FunChatMessageCallCell

- (void)commonUILeft {
    [super commonUILeft];
    [self.bubbleImageLeft addSubview:self.callBodyBackgroundViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.callBodyBackgroundViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:self.funMargin + 4],
        [self.callBodyBackgroundViewLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor constant:4],
        [self.callBodyBackgroundViewLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-4],
        [self.callBodyBackgroundViewLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor constant:-4],
    ]];
    [self.bubbleImageLeft addSubview:self.contentLabelLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor constant:-chat_content_margin],
        [self.contentLabelLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor constant:chat_content_margin + self.funMargin],
        [self.contentLabelLeft.centerYAnchor constraintEqualToAnchor:self.bubbleImageLeft.centerYAnchor],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.bubbleImageRight addSubview:self.callBodyBackgroundViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.callBodyBackgroundViewRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor constant:4],
        [self.callBodyBackgroundViewRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor constant:4],
        [self.callBodyBackgroundViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor constant:-(self.funMargin + 4)],
        [self.callBodyBackgroundViewRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor constant:-4],
    ]];
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
    [self updateCallBodyBackgrounds];
}

- (CGFloat)reactionTopSpacingForModel:(MessageContentModel *)model {
    return model.type == MessageTypeRtcCallRecord ? 0.0 : [super reactionTopSpacingForModel:model];
}

- (UIView *)callBodyBackgroundViewLeft {
    if (!_callBodyBackgroundViewLeft) {
        _callBodyBackgroundViewLeft = [self makeCallBodyBackgroundView];
    }
    return _callBodyBackgroundViewLeft;
}

- (UIView *)callBodyBackgroundViewRight {
    if (!_callBodyBackgroundViewRight) {
        _callBodyBackgroundViewRight = [self makeCallBodyBackgroundView];
    }
    return _callBodyBackgroundViewRight;
}

- (UIView *)makeCallBodyBackgroundView {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.userInteractionEnabled = NO;
    view.hidden = YES;
    view.layer.cornerRadius = 4;
    return view;
}

- (void)updateCallBodyBackgrounds {
    [self updateCallBodyBackground:self.callBodyBackgroundViewLeft
                         displayed:self.reactionViewLeft.enabledForDisplay
                             color:UIColor.ne_chatReactionReceiveBackground];
    [self updateCallBodyBackground:self.callBodyBackgroundViewRight
                         displayed:self.reactionViewRight.enabledForDisplay
                             color:UIColor.ne_chatReactionContentBackground];
}

- (void)updateCallBodyBackground:(UIView *)view displayed:(BOOL)displayed color:(UIColor *)color {
    view.hidden = !displayed;
    view.backgroundColor = displayed ? color : UIColor.clearColor;
    view.layer.borderWidth = displayed ? 0.5 : 0;
    view.layer.borderColor = displayed ? UIColor.ne_chatReactionBorder.CGColor : UIColor.clearColor.CGColor;
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
