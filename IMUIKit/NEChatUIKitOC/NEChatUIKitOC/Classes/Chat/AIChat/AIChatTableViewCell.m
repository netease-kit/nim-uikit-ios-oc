// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIChatTableViewCell.h"
#import "UIImage+Chat.h"
#import "ChatCellConstantValue.h"

@implementation AIChatTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonUI];
    }
    return self;
}

- (void)commonUI {
    [self.contentView addSubview:self.backView];
    [NSLayoutConstraint activateConstraints:@[
        [self.backView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
        [self.backView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
        [self.backView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
        [self.backView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],
    ]];
}

- (void)editButtonAction {
    [self.delegate didClickEditButton:self.contentLabel.text];
}

- (void)setModel:(AIChatCellModel *)model {
    self.tagLabel.text = model.tagTitle;
    self.tagLabel.textColor = model.tagTitleColor;
    self.tagLabel.backgroundColor = model.tagTitleBackgroundColor;
    self.contentLabel.text = model.contentTitle;
}

#pragma mark - Lazy Load

- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] init];
        _backView.translatesAutoresizingMaskIntoConstraints = NO;
        _backView.backgroundColor = [UIColor whiteColor];
        _backView.layer.cornerRadius = 12;

        [_backView addSubview:self.tagLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.tagLabel.leftAnchor constraintEqualToAnchor:_backView.leftAnchor constant:chat_content_margin],
            [self.tagLabel.centerYAnchor constraintEqualToAnchor:_backView.centerYAnchor],
            [self.tagLabel.widthAnchor constraintEqualToConstant:60],
            [self.tagLabel.heightAnchor constraintEqualToConstant:24],
        ]];

        [_backView addSubview:self.editButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.editButton.centerYAnchor constraintEqualToAnchor:_backView.centerYAnchor],
            [self.editButton.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-12],
            [self.editButton.widthAnchor constraintEqualToConstant:24],
            [self.editButton.heightAnchor constraintEqualToConstant:24],
        ]];

        [_backView addSubview:self.contentLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.contentLabel.leftAnchor constraintEqualToAnchor:self.tagLabel.rightAnchor constant:10],
            [self.contentLabel.rightAnchor constraintEqualToAnchor:self.editButton.leftAnchor constant:-chat_content_margin],
            [self.contentLabel.topAnchor constraintEqualToAnchor:_backView.topAnchor constant:chat_content_margin],
            [self.contentLabel.bottomAnchor constraintEqualToAnchor:_backView.bottomAnchor constant:-chat_content_margin],
        ]];
    }
    return _backView;
}

- (UILabel *)tagLabel {
    if (!_tagLabel) {
        _tagLabel = [[UILabel alloc] init];
        _tagLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _tagLabel.font = [UIFont systemFontOfSize:12];
        _tagLabel.textAlignment = NSTextAlignmentCenter;
        _tagLabel.layer.cornerRadius = 6;
        _tagLabel.layer.masksToBounds = YES;
    }
    return _tagLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.numberOfLines = 2;
    }
    return _contentLabel;
}

- (ExpandButton *)editButton {
    if (!_editButton) {
        _editButton = [[ExpandButton alloc] init];
        _editButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_editButton setImage:[UIImage ne_imageNamed:@"ai_edit"] forState:UIControlStateNormal];
        [_editButton addTarget:self action:@selector(editButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _editButton;
}

@end
