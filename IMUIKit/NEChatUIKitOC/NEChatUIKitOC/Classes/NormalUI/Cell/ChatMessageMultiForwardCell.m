// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatMessageMultiForwardCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NEAppLanguageUtil.h>
#import <NEChatKitOC/NECustomUtils.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import "NEChatUIConstant.h"
#import "NSString+Chat.h"

static CGFloat const kChatMessageMultiForwardContentWidth = 234;
static CGFloat const kChatMessageMultiForwardTitleLabelFontSize = 14;

@implementation ChatMessageMultiForwardCell

- (UIImageView *)backViewLeft {
    if (!_backViewLeft) {
        _backViewLeft = [[UIImageView alloc] init];
        _backViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _backViewLeft;
}

- (UILabel *)titleLabelLeft1 {
    if (!_titleLabelLeft1) {
        _titleLabelLeft1 = [[UILabel alloc] init];
        _titleLabelLeft1.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelLeft1.accessibilityIdentifier = @"id.name1";
    }
    return _titleLabelLeft1;
}

- (UILabel *)titleLabelLeft2 {
    if (!_titleLabelLeft2) {
        _titleLabelLeft2 = [[UILabel alloc] init];
        _titleLabelLeft2.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelLeft2.text = chatLocalizable(@"chat_history_by");
        _titleLabelLeft2.textColor = UIColor.ne_darkText;
        _titleLabelLeft2.font = [UIFont systemFontOfSize:kChatMessageMultiForwardTitleLabelFontSize weight:UIFontWeightSemibold];
        _titleLabelLeft2.accessibilityIdentifier = @"id.name2";
    }
    return _titleLabelLeft2;
}

- (UILabel *)contentLabelLeft1 {
    if (!_contentLabelLeft1) {
        _contentLabelLeft1 = [[UILabel alloc] init];
        _contentLabelLeft1.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft1.numberOfLines = 3;
        _contentLabelLeft1.accessibilityIdentifier = @"id.content1";
    }
    return _contentLabelLeft1;
}

- (UILabel *)contentLabelLeft2 {
    if (!_contentLabelLeft2) {
        _contentLabelLeft2 = [[UILabel alloc] init];
        _contentLabelLeft2.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft2.numberOfLines = 2;
        _contentLabelLeft2.accessibilityIdentifier = @"id.content2";
    }
    return _contentLabelLeft2;
}

- (UILabel *)contentLabelLeft3 {
    if (!_contentLabelLeft3) {
        _contentLabelLeft3 = [[UILabel alloc] init];
        _contentLabelLeft3.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft3.accessibilityIdentifier = @"id.content3";
    }
    return _contentLabelLeft3;
}

- (UIView *)dividerLineLeft {
    if (!_dividerLineLeft) {
        _dividerLineLeft = [[UIView alloc] init];
        _dividerLineLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _dividerLineLeft.backgroundColor = multiForwardLineColor();
    }
    return _dividerLineLeft;
}

- (UILabel *)contentHistoryLeft {
    if (!_contentHistoryLeft) {
        _contentHistoryLeft = [[UILabel alloc] init];
        _contentHistoryLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _contentHistoryLeft.font = [UIFont systemFontOfSize:12];
        _contentHistoryLeft.textColor = UIColor.ne_lightText;
        _contentHistoryLeft.text = chatLocalizable(@"chat_history");
        _contentHistoryLeft.textAlignment = NSTextAlignmentLeft;
        _contentHistoryLeft.accessibilityIdentifier = @"id.contentHistoryLeft";
    }
    return _contentHistoryLeft;
}

- (UIImageView *)backViewRight {
    if (!_backViewRight) {
        _backViewRight = [[UIImageView alloc] init];
        _backViewRight.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _backViewRight;
}

- (UILabel *)titleLabelRight1 {
    if (!_titleLabelRight1) {
        _titleLabelRight1 = [[UILabel alloc] init];
        _titleLabelRight1.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelRight1.accessibilityIdentifier = @"id.name1";
    }
    return _titleLabelRight1;
}

- (UILabel *)titleLabelRight2 {
    if (!_titleLabelRight2) {
        _titleLabelRight2 = [[UILabel alloc] init];
        _titleLabelRight2.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelRight2.text = chatLocalizable(@"chat_history_by");
        _titleLabelRight2.textColor = UIColor.ne_darkText;
        _titleLabelRight2.font = [UIFont systemFontOfSize:kChatMessageMultiForwardTitleLabelFontSize weight:UIFontWeightSemibold];
        _titleLabelRight2.accessibilityIdentifier = @"id.name2";
    }
    return _titleLabelRight2;
}

- (UILabel *)contentLabelRight1 {
    if (!_contentLabelRight1) {
        _contentLabelRight1 = [[UILabel alloc] init];
        _contentLabelRight1.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelRight1.numberOfLines = 3;
        _contentLabelRight1.accessibilityIdentifier = @"id.content1";
    }
    return _contentLabelRight1;
}

- (UILabel *)contentLabelRight2 {
    if (!_contentLabelRight2) {
        _contentLabelRight2 = [[UILabel alloc] init];
        _contentLabelRight2.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelRight2.numberOfLines = 2;
        _contentLabelRight2.accessibilityIdentifier = @"id.content2";
    }
    return _contentLabelRight2;
}

- (UILabel *)contentLabelRight3 {
    if (!_contentLabelRight3) {
        _contentLabelRight3 = [[UILabel alloc] init];
        _contentLabelRight3.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelRight3.accessibilityIdentifier = @"id.content3";
    }
    return _contentLabelRight3;
}

- (UIView *)dividerLineRight {
    if (!_dividerLineRight) {
        _dividerLineRight = [[UIView alloc] init];
        _dividerLineRight.translatesAutoresizingMaskIntoConstraints = NO;
        _dividerLineRight.backgroundColor = multiForwardLineColor();
    }
    return _dividerLineRight;
}

- (UILabel *)contentHistoryRight {
    if (!_contentHistoryRight) {
        _contentHistoryRight = [[UILabel alloc] init];
        _contentHistoryRight.translatesAutoresizingMaskIntoConstraints = NO;
        _contentHistoryRight.font = [UIFont systemFontOfSize:12];
        _contentHistoryRight.textColor = UIColor.ne_lightText;
        _contentHistoryRight.text = chatLocalizable(@"chat_history");
        _contentHistoryRight.textAlignment = NSTextAlignmentLeft;
        _contentHistoryRight.accessibilityIdentifier = @"id.contentHistoryRight";
    }
    return _contentHistoryRight;
}

- (void)commonUILeft {
    self.bubbleImageLeft.image = nil;
    UIImage *image = chatLoadImage(@"multiForward_message_receive");
    UIEdgeInsets capInsets = [ChatUIConfig shared].messageProperties.backgroundImageCapInsets;
    if (capInsets.top != 0 || capInsets.left != 0) {
        self.backViewLeft.image = [image resizableImageWithCapInsets:capInsets];
    } else {
        self.backViewLeft.image = image;
        self.backViewLeft.contentMode = UIViewContentModeScaleAspectFill;
    }

    [self.bubbleImageLeft addSubview:self.backViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.backViewLeft.leftAnchor constraintEqualToAnchor:self.bubbleImageLeft.leftAnchor],
        [self.backViewLeft.topAnchor constraintEqualToAnchor:self.bubbleImageLeft.topAnchor],
        [self.backViewLeft.bottomAnchor constraintEqualToAnchor:self.bubbleImageLeft.bottomAnchor],
        [self.backViewLeft.rightAnchor constraintEqualToAnchor:self.bubbleImageLeft.rightAnchor],
    ]];

    BOOL isEnglish = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish;
    [self.backViewLeft addSubview:self.titleLabelLeft1];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelLeft1.leftAnchor constraintEqualToAnchor:self.backViewLeft.leftAnchor constant:16],
        [self.titleLabelLeft1.rightAnchor constraintLessThanOrEqualToAnchor:self.backViewLeft.rightAnchor constant:isEnglish ? -100 : -84],
        [self.titleLabelLeft1.topAnchor constraintEqualToAnchor:self.backViewLeft.topAnchor constant:10],
        [self.titleLabelLeft1.heightAnchor constraintEqualToConstant:22],
    ]];

    [self.backViewLeft addSubview:self.titleLabelLeft2];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelLeft2.leftAnchor constraintEqualToAnchor:self.titleLabelLeft1.rightAnchor],
        [self.titleLabelLeft2.centerYAnchor constraintEqualToAnchor:self.titleLabelLeft1.centerYAnchor],
        [self.titleLabelLeft2.heightAnchor constraintEqualToConstant:22],
        [self.titleLabelLeft2.widthAnchor constraintEqualToConstant:isEnglish ? 90 : 74],
    ]];

    [self.backViewLeft addSubview:self.contentLabelLeft1];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft1.leftAnchor constraintEqualToAnchor:self.titleLabelLeft1.leftAnchor],
        [self.contentLabelLeft1.topAnchor constraintEqualToAnchor:self.titleLabelLeft1.bottomAnchor constant:2],
        [self.contentLabelLeft1.widthAnchor constraintEqualToConstant:kChatMessageMultiForwardContentWidth],
        [self.contentLabelLeft1.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backViewLeft addSubview:self.contentLabelLeft2];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft2.leftAnchor constraintEqualToAnchor:self.contentLabelLeft1.leftAnchor],
        [self.contentLabelLeft2.topAnchor constraintEqualToAnchor:self.contentLabelLeft1.bottomAnchor],
        [self.contentLabelLeft2.widthAnchor constraintEqualToConstant:kChatMessageMultiForwardContentWidth],
        [self.contentLabelLeft2.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backViewLeft addSubview:self.contentLabelLeft3];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelLeft3.leftAnchor constraintEqualToAnchor:self.contentLabelLeft2.leftAnchor],
        [self.contentLabelLeft3.topAnchor constraintEqualToAnchor:self.contentLabelLeft2.bottomAnchor],
        [self.contentLabelLeft3.widthAnchor constraintEqualToConstant:kChatMessageMultiForwardContentWidth],
        [self.contentLabelLeft3.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backViewLeft addSubview:self.contentHistoryLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentHistoryLeft.leftAnchor constraintEqualToAnchor:self.titleLabelLeft1.leftAnchor],
        [self.contentHistoryLeft.bottomAnchor constraintEqualToAnchor:self.backViewLeft.bottomAnchor constant:-12],
        [self.contentHistoryLeft.heightAnchor constraintEqualToConstant:14],
    ]];

    [self.backViewLeft addSubview:self.dividerLineLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.dividerLineLeft.leftAnchor constraintEqualToAnchor:self.backViewLeft.leftAnchor constant:6],
        [self.dividerLineLeft.rightAnchor constraintEqualToAnchor:self.backViewLeft.rightAnchor constant:-6],
        [self.dividerLineLeft.topAnchor constraintEqualToAnchor:self.contentHistoryLeft.topAnchor constant:-6],
        [self.dividerLineLeft.heightAnchor constraintEqualToConstant:1],
    ]];
}

- (void)commonUIRight {
    self.bubbleImageRight.image = nil;
    UIImage *image = chatLoadImage(@"multiForward_message_send");
    UIEdgeInsets capInsets = [ChatUIConfig shared].messageProperties.backgroundImageCapInsets;
    if (capInsets.top != 0 || capInsets.left != 0) {
        self.backViewRight.image = [image resizableImageWithCapInsets:capInsets];
    } else {
        self.backViewRight.image = image;
        self.backViewRight.contentMode = UIViewContentModeScaleAspectFill;
    }

    [self.bubbleImageRight addSubview:self.backViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.backViewRight.leftAnchor constraintEqualToAnchor:self.bubbleImageRight.leftAnchor],
        [self.backViewRight.topAnchor constraintEqualToAnchor:self.bubbleImageRight.topAnchor],
        [self.backViewRight.bottomAnchor constraintEqualToAnchor:self.bubbleImageRight.bottomAnchor],
        [self.backViewRight.rightAnchor constraintEqualToAnchor:self.bubbleImageRight.rightAnchor],
    ]];

    BOOL isEnglish = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish;
    [self.backViewRight addSubview:self.titleLabelRight1];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelRight1.leftAnchor constraintEqualToAnchor:self.backViewRight.leftAnchor constant:16],
        [self.titleLabelRight1.rightAnchor constraintLessThanOrEqualToAnchor:self.backViewRight.rightAnchor constant:isEnglish ? -100 : -84],
        [self.titleLabelRight1.topAnchor constraintEqualToAnchor:self.backViewRight.topAnchor constant:10],
        [self.titleLabelRight1.heightAnchor constraintEqualToConstant:22],
    ]];

    [self.backViewRight addSubview:self.titleLabelRight2];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabelRight2.leftAnchor constraintEqualToAnchor:self.titleLabelRight1.rightAnchor],
        [self.titleLabelRight2.centerYAnchor constraintEqualToAnchor:self.titleLabelRight1.centerYAnchor],
        [self.titleLabelRight2.heightAnchor constraintEqualToConstant:22],
        [self.titleLabelRight2.widthAnchor constraintEqualToConstant:isEnglish ? 90 : 74],
    ]];

    [self.backViewRight addSubview:self.contentLabelRight1];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRight1.leftAnchor constraintEqualToAnchor:self.titleLabelRight1.leftAnchor],
        [self.contentLabelRight1.topAnchor constraintEqualToAnchor:self.titleLabelRight1.bottomAnchor constant:2],
        [self.contentLabelRight1.widthAnchor constraintEqualToConstant:kChatMessageMultiForwardContentWidth],
        [self.contentLabelRight1.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backViewRight addSubview:self.contentLabelRight2];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRight2.leftAnchor constraintEqualToAnchor:self.contentLabelRight1.leftAnchor],
        [self.contentLabelRight2.topAnchor constraintEqualToAnchor:self.contentLabelRight1.bottomAnchor],
        [self.contentLabelRight2.widthAnchor constraintEqualToConstant:kChatMessageMultiForwardContentWidth],
        [self.contentLabelRight2.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backViewRight addSubview:self.contentLabelRight3];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabelRight3.leftAnchor constraintEqualToAnchor:self.contentLabelRight2.leftAnchor],
        [self.contentLabelRight3.topAnchor constraintEqualToAnchor:self.contentLabelRight2.bottomAnchor],
        [self.contentLabelRight3.widthAnchor constraintEqualToConstant:kChatMessageMultiForwardContentWidth],
        [self.contentLabelRight3.heightAnchor constraintGreaterThanOrEqualToConstant:20],
    ]];

    [self.backViewRight addSubview:self.contentHistoryRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentHistoryRight.leftAnchor constraintEqualToAnchor:self.titleLabelRight1.leftAnchor],
        [self.contentHistoryRight.bottomAnchor constraintEqualToAnchor:self.backViewRight.bottomAnchor constant:-12],
        [self.contentHistoryRight.heightAnchor constraintEqualToConstant:14],
    ]];

    [self.backViewRight addSubview:self.dividerLineRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.dividerLineRight.leftAnchor constraintEqualToAnchor:self.backViewRight.leftAnchor constant:6],
        [self.dividerLineRight.rightAnchor constraintEqualToAnchor:self.backViewRight.rightAnchor constant:-6],
        [self.dividerLineRight.topAnchor constraintEqualToAnchor:self.contentHistoryRight.topAnchor constant:-6],
        [self.dividerLineRight.heightAnchor constraintEqualToConstant:1],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    NSDictionary *data = [NECustomUtils dataOfCustomMessage:model.message.attachment];
    if (!data) return;

    UIFont *font = [UIFont systemFontOfSize:kChatMessageMultiForwardTitleLabelFontSize];
    NSLayoutConstraint *bubbleW = isSend ? self.bubbleWRight : self.bubbleWLeft;
    NSLayoutConstraint *bubbleH = isSend ? self.bubbleHRight : self.bubbleHLeft;
    UILabel *titleLabel = isSend ? self.titleLabelRight1 : self.titleLabelLeft1;
    UILabel *titleLabel2 = isSend ? self.titleLabelRight2 : self.titleLabelLeft2;
    UILabel *contentLabel1 = isSend ? self.contentLabelRight1 : self.contentLabelLeft1;
    UILabel *contentLabel2 = isSend ? self.contentLabelRight2 : self.contentLabelLeft2;
    UILabel *contentLabel3 = isSend ? self.contentLabelRight3 : self.contentLabelLeft3;

    bubbleW.constant = 266;
    bubbleH.constant = 130;

    titleLabel.attributedText = nil;
    titleLabel2.text = chatLocalizable(@"chat_history_by");
    contentLabel1.attributedText = nil;
    contentLabel2.attributedText = nil;
    contentLabel3.attributedText = nil;
    contentLabel1.hidden = NO;
    contentLabel2.hidden = YES;
    contentLabel3.hidden = YES;

    NSString *sessionName = [data[@"sessionName"] isKindOfClass:[NSString class]] ? data[@"sessionName"] : nil;
    if (sessionName.length > 0) {
        titleLabel.attributedText = [NEEmotionTool getAttWithStr:sessionName font:[UIFont systemFontOfSize:kChatMessageMultiForwardTitleLabelFontSize weight:UIFontWeightSemibold] color:UIColor.ne_darkText offset:CGPointMake(0, -4)];
    } else {
        titleLabel2.text = chatLocalizable(@"chat_history");
    }

    NSArray *abstracts = [data[@"abstracts"] isKindOfClass:[NSArray class]] ? data[@"abstracts"] : nil;
    if (!abstracts) return;

    for (NSInteger i = 0; i < MIN(abstracts.count, 3); i++) {
        UILabel *contentLabel = contentLabel1;
        if (i == 1) contentLabel = contentLabel2;
        else if (i == 2) contentLabel = contentLabel3;

        NSDictionary *abstract = [abstracts[i] isKindOfClass:[NSDictionary class]] ? abstracts[i] : nil;
        if (!abstract) continue;
        NSString *contentText = @"";
        NSString *senderNick = [abstract[@"senderNick"] isKindOfClass:[NSString class]] ? abstract[@"senderNick"] : nil;
        if (senderNick) {
            contentText = [NEFriendUserCache getCutName:senderNick];
            NSString *content = [abstract[@"content"] isKindOfClass:[NSString class]] ? abstract[@"content"] : nil;
            if (content) {
                contentText = [contentText stringByAppendingString:[NSString stringWithFormat:@"：%@", content]];
            }
        }

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 1;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        NSMutableAttributedString *attributedText = [NEEmotionTool getAttWithStr:contentText font:font color:UIColor.ne_lightText offset:CGPointMake(0, -4)];
        [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedText.length)];
        contentLabel.attributedText = attributedText;
    }

    NSInteger numCount1 = [NSString calculateMaxLinesWithWidth:kChatMessageMultiForwardContentWidth attributeString:contentLabel1.attributedText font:font];
    if (numCount1 == 1) {
        contentLabel2.numberOfLines = 2;
        contentLabel2.hidden = contentLabel2.attributedText == nil;
        NSInteger numCount2 = [NSString calculateMaxLinesWithWidth:kChatMessageMultiForwardContentWidth attributeString:contentLabel2.attributedText font:font];
        contentLabel3.hidden = contentLabel3.attributedText == nil || numCount2 >= 2;
    } else if (numCount1 == 2) {
        contentLabel2.numberOfLines = 1;
        contentLabel2.hidden = contentLabel2.attributedText == nil;
        contentLabel3.hidden = YES;
    } else {
        contentLabel2.hidden = YES;
        contentLabel3.hidden = YES;
    }
}

@end
