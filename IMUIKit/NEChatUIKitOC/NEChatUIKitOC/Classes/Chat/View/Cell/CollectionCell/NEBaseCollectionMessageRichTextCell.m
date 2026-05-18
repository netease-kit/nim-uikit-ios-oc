// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageRichTextCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "ChatUIConfig.h"
#import "MessageContentModel.h"
#import "MessageRichTextModel.h"

@implementation NEBaseCollectionMessageRichTextCell

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

- (UILabel *)collectionTitleLabel {
    if (!_collectionTitleLabel) {
        _collectionTitleLabel = [[UILabel alloc] init];
        _collectionTitleLabel.font = [UIFont systemFontOfSize:[ChatUIConfig shared].messageProperties.pinMessageTextSize];
        _collectionTitleLabel.textColor = UIColor.ne_darkText;
        _collectionTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionTitleLabel.userInteractionEnabled = YES;
        _collectionTitleLabel.numberOfLines = 1;
    }
    return _collectionTitleLabel;
}

- (void)setupCustomUI {
    self.collectionContentLabel.numberOfLines = 2;
    [self.backView addSubview:self.collectionContentLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionContentLabel.leftAnchor constraintEqualToAnchor:self.line.leftAnchor],
        [self.collectionContentLabel.rightAnchor constraintEqualToAnchor:self.line.rightAnchor],
        [self.collectionContentLabel.bottomAnchor constraintEqualToAnchor:self.line.topAnchor constant:-12],
    ]];

    [self.backView addSubview:self.collectionTitleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionTitleLabel.leftAnchor constraintEqualToAnchor:self.line.leftAnchor],
        [self.collectionTitleLabel.rightAnchor constraintEqualToAnchor:self.line.rightAnchor],
        [self.collectionTitleLabel.bottomAnchor constraintEqualToAnchor:self.collectionContentLabel.topAnchor constant:-1],
    ]];

    UITapGestureRecognizer *titleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentClick)];
    [self.collectionTitleLabel addGestureRecognizer:titleGesture];
}

- (void)setupCommonUI {
    [super setupCommonUI];
}

- (void)configureData:(CollectionMessageModel *)model {
    [super configureData:model];
    if ([model.chatmodel isKindOfClass:[MessageRichTextModel class]]) {
        MessageRichTextModel *m = (MessageRichTextModel *)model.chatmodel;
        self.collectionTitleLabel.attributedText = m.titleAttributeStr;
    }
}

@end
