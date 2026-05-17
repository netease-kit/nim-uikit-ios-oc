// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageRichTextCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "ChatUIConfig.h"
#import "MessageContentModel.h"
#import "MessageRichTextModel.h"
#import <NECommonUIKitOC/NELinkableLabel.h>

@implementation NEBasePinMessageRichTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.pinMessageTextSize];
        _titleLabel.textColor = UIColor.ne_darkText;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.userInteractionEnabled = YES;
        _titleLabel.numberOfLines = 1;
    }
    return _titleLabel;
}

- (void)commonUI {
    [self.backView addSubview:self.titleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leftAnchor constraintEqualToAnchor:self.line.leftAnchor],
        [self.titleLabel.rightAnchor constraintEqualToAnchor:self.line.rightAnchor],
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.line.bottomAnchor constant:12],
    ]];

    self.contentLabel.numberOfLines = 2;
    [self.backView addSubview:self.contentLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabel.leftAnchor constraintEqualToAnchor:self.line.leftAnchor],
        [self.contentLabel.rightAnchor constraintEqualToAnchor:self.line.rightAnchor],
        [self.contentLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:1],
    ]];

    UITapGestureRecognizer *titleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentClick)];
    [self.titleLabel addGestureRecognizer:titleGesture];
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    if ([item.chatmodel isKindOfClass:[MessageRichTextModel class]]) {
        MessageRichTextModel *model = (MessageRichTextModel *)item.chatmodel;
        self.titleLabel.attributedText = model.titleAttributeStr;
    }
}

@end
