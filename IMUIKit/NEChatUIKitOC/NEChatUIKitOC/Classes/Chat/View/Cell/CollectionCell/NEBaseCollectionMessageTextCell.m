// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageTextCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "ChatUIConfig.h"
#import "MessageContentModel.h"
#import "MessageTextModel.h"

@implementation NEBaseCollectionMessageTextCell

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

- (NELinkableLabel *)collectionContentLabel {
    if (!_collectionContentLabel) {
        _collectionContentLabel = [[NELinkableLabel alloc] init];
        _collectionContentLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.pinMessageTextSize];
        _collectionContentLabel.textColor = UIColor.ne_darkText;
        _collectionContentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionContentLabel.userInteractionEnabled = YES;
        _collectionContentLabel.numberOfLines = 3;
        _collectionContentLabel.delegate = self;
        _collectionContentLabel.accessibilityIdentifier = @"id.message";
    }
    return _collectionContentLabel;
}

- (UILabel *)replyLabel {
    if (!_replyLabel) {
        _replyLabel = [[UILabel alloc] init];
    }
    return _replyLabel;
}

- (void)setupCustomUI {
    [self.backView addSubview:self.collectionContentLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionContentLabel.leftAnchor constraintEqualToAnchor:self.line.leftAnchor],
        [self.collectionContentLabel.rightAnchor constraintEqualToAnchor:self.line.rightAnchor],
        [self.collectionContentLabel.bottomAnchor constraintEqualToAnchor:self.line.topAnchor constant:-12],
    ]];
}

- (void)setupCommonUI {
    [super setupCommonUI];
    [self setupCustomUI];
}

- (void)configureData:(CollectionMessageModel *)model {
    [super configureData:model];
    if ([model.chatmodel isKindOfClass:[MessageTextModel class]]) {
        MessageTextModel *textModel = (MessageTextModel *)model.chatmodel;
        self.collectionContentLabel.attributedText = textModel.attributeStr;
        [self.collectionContentLabel updateLinkDetection];
    }
}

#pragma mark - LinkableLabelProtocol

- (void)didTapLink:(NSURL *)url {
    if ([self.delegate respondsToSelector:@selector(didTapDetectedLink:cell:url:)]) {
        [self.delegate didTapDetectedLink:self.collectionModel cell:self url:url];
    }
}

@end
