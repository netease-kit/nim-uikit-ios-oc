// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageCell.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "ChatMessageHelper.h"
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "NEChatUIConstant.h"
#import <NEChatKitOC/NEConstant.h>

@implementation NEBaseCollectionMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentClick)];
        [self setupCommonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (NEUserHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
        _headerView.titleLabel.font = [NEConstant defaultTextFont:12];
        _headerView.titleLabel.textColor = UIColor.whiteColor;
        _headerView.layer.cornerRadius = 16;
        _headerView.clipsToBounds = YES;
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _headerView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont systemFontOfSize:14.0];
        _nameLabel.textColor = UIColor.ne_darkText;
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.accessibilityIdentifier = @"id.name";
    }
    return _nameLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12.0];
        _timeLabel.textColor = UIColor.ne_greyText;
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.accessibilityIdentifier = @"id.time";
    }
    return _timeLabel;
}

- (UILabel *)conversationLabel {
    if (!_conversationLabel) {
        _conversationLabel = [[UILabel alloc] init];
        _conversationLabel.font = [UIFont systemFontOfSize:14.0];
        _conversationLabel.textColor = UIColor.ne_greyText;
        _conversationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _conversationLabel.accessibilityIdentifier = @"id.conversation";
    }
    return _conversationLabel;
}

- (void)setupCommonUI {
    self.contentView.backgroundColor = UIColor.clearColor;

    _backView = [[UIView alloc] init];
    _backView.translatesAutoresizingMaskIntoConstraints = NO;
    _backView.backgroundColor = UIColor.whiteColor;
    _backView.clipsToBounds = YES;
    _backView.layer.cornerRadius = 8.0;
    [self.contentView addSubview:_backView];

    self.backLeftConstraint = [_backView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20];
    self.backLeftConstraint.active = YES;
    self.backRightConstraint = [_backView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20];
    self.backRightConstraint.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [_backView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        [_backView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];

    [_backView addSubview:self.headerView];
    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.leftAnchor constraintEqualToAnchor:_backView.leftAnchor constant:16],
        [self.headerView.topAnchor constraintEqualToAnchor:_backView.topAnchor constant:16],
        [self.headerView.widthAnchor constraintEqualToConstant:32],
        [self.headerView.heightAnchor constraintEqualToConstant:32],
    ]];

    UIImage *image = [coreLoader() loadImage:@"three_point"];
    _moreImageView = [[UIImageView alloc] init];
    _moreImageView.image = image;
    _moreImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [_backView addSubview:_moreImageView];

    UIButton *moreButton = [[UIButton alloc] init];
    [moreButton addTarget:self action:@selector(moreClick) forControlEvents:UIControlEventTouchUpInside];
    moreButton.accessibilityIdentifier = @"id.moreAction";
    moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_backView addSubview:moreButton];
    [NSLayoutConstraint activateConstraints:@[
        [moreButton.rightAnchor constraintEqualToAnchor:_backView.rightAnchor],
        [moreButton.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [moreButton.widthAnchor constraintEqualToConstant:50],
        [moreButton.heightAnchor constraintEqualToConstant:40],
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [_moreImageView.centerYAnchor constraintEqualToAnchor:self.headerView.centerYAnchor],
        [_moreImageView.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-20],
    ]];

    [_backView addSubview:self.nameLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.nameLabel.leftAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:8],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
        [self.nameLabel.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-50],
    ]];

    [_backView addSubview:self.timeLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.timeLabel.leftAnchor constraintEqualToAnchor:_backView.leftAnchor constant:16],
        [self.timeLabel.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-16],
        [self.timeLabel.bottomAnchor constraintEqualToAnchor:_backView.bottomAnchor constant:-12],
    ]];

    _line = [[UIView alloc] init];
    [_backView addSubview:_line];
    _line.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_line.leftAnchor constraintEqualToAnchor:_backView.leftAnchor constant:16],
        [_line.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-16],
        [_line.bottomAnchor constraintEqualToAnchor:_backView.bottomAnchor constant:-38],
        [_line.heightAnchor constraintEqualToConstant:1],
    ]];
    _line.backgroundColor = UIColor.ne_greyLine;

    [_backView addSubview:self.conversationLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.conversationLabel.leftAnchor constraintEqualToAnchor:self.nameLabel.leftAnchor],
        [self.conversationLabel.rightAnchor constraintEqualToAnchor:self.nameLabel.rightAnchor],
        [self.conversationLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:2],
    ]];
}

- (void)configureData:(CollectionMessageModel *)model {
    self.collectionModel = model;
    [self.headerView configHeadData:model.chatmodel.avatar
                               name:model.chatmodel.shortName ?: @""
                                uid:[ChatMessageHelper getSenderId:model.chatmodel.message] ?: @""];
    self.nameLabel.text = model.chatmodel.fullName;

    NSTimeInterval time = 0;
    if (model.collection && model.collection.updateTime > 0) {
        time = model.collection.updateTime;
    } else if (model.message) {
        time = model.message.createTime;
    }
    if (time > 0) {
        self.timeLabel.text = [ChatMessageHelper ne_stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]];
    }

    if (model.message.conversationType == V2NIM_CONVERSATION_TYPE_P2P) {
        if (model.conversationName) {
            self.conversationLabel.text = [NSString stringWithFormat:chatLocalizable(@"chat_collection_p2p_tip"), model.conversationName];
        }
    } else if (model.message.conversationType == V2NIM_CONVERSATION_TYPE_TEAM ||
               model.message.conversationType == V2NIM_CONVERSATION_TYPE_SUPER_TEAM) {
        if (model.conversationName) {
            self.conversationLabel.text = [NSString stringWithFormat:chatLocalizable(@"chat_collection_team_tip"), model.conversationName];
        }
    }

    self.contentWidth.constant = model.chatmodel.contentSize.width;
    self.contentHeight.constant = model.chatmodel.contentSize.height;
}

- (void)moreClick {
    [self.delegate didClickMore:self.collectionModel];
}

- (void)contentClick {
    [self.delegate didClickContent:self.collectionModel cell:self];
}

- (void)setFunStyle {
    self.backLeftConstraint.constant = 0;
    self.backRightConstraint.constant = 0;
    self.backView.layer.cornerRadius = 0;
    self.headerView.layer.cornerRadius = 4.0;
}

@end
