// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageTextCell.h"
#import "ChatUIConfig.h"
#import "MessageContentModel.h"
#import "MessageTextModel.h"
#import <NECommonUIKitOC/NELinkableLabel.h>
#import "NEEmotionTool.h"

@implementation NEBasePinMessageTextCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (NELinkableLabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[NELinkableLabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.pinMessageTextSize];
        _contentLabel.textColor = UIColor.ne_darkText;
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabel.userInteractionEnabled = YES;
        _contentLabel.numberOfLines = 3;
        _contentLabel.delegate = self;
        _contentLabel.accessibilityIdentifier = @"id.message";
    }
    return _contentLabel;
}

- (UILabel *)replyLabel {
    if (!_replyLabel) {
        _replyLabel = [[UILabel alloc] init];
    }
    return _replyLabel;
}

- (void)setupUI {
    [super setupUI];
    [self commonUI];
}

- (void)commonUI {
    self.replyLabel.font = [UIFont systemFontOfSize:12];
    self.replyLabel.textColor = [UIColor ne_colorWithHexString:@"#929299"];
    self.replyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.replyLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.replyLabel.topAnchor constraintEqualToAnchor:self.line.bottomAnchor constant:12],
        [self.replyLabel.leftAnchor constraintEqualToAnchor:self.line.leftAnchor],
        [self.replyLabel.rightAnchor constraintEqualToAnchor:self.line.rightAnchor],
    ]];

    [self.backView addSubview:self.contentLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabel.leftAnchor constraintEqualToAnchor:self.line.leftAnchor],
        [self.contentLabel.rightAnchor constraintEqualToAnchor:self.line.rightAnchor],
        [self.contentLabel.topAnchor constraintEqualToAnchor:self.replyLabel.bottomAnchor constant:1],
    ]];
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    if ([item.chatmodel isKindOfClass:[MessageTextModel class]]) {
        MessageTextModel *model = (MessageTextModel *)item.chatmodel;
        self.contentLabel.attributedText = model.attributeStr;
        [self.contentLabel updateLinkDetection];
        if (model.isReply) {
            self.replyLabel.attributedText = [NEEmotionTool getAttWithStr:model.replyText ?: @""
                                                                     font:self.replyLabel.font
                                                                    color:self.replyLabel.textColor
                                                                   offset:CGPointMake(0, -4)];
        } else {
            self.replyLabel.attributedText = nil;
        }
    }
}

#pragma mark - LinkableLabelProtocol

- (void)didTapLink:(NSURL *)url {
    if ([self.delegate respondsToSelector:@selector(didTapDetectedLink:cell:url:)]) {
        [self.delegate didTapDetectedLink:self.pinModel cell:self url:url];
    }
}

@end
