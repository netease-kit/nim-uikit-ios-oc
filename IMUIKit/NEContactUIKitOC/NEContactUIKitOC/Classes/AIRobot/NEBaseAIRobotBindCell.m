// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAIRobotBindCell.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation NEBaseAIRobotBindCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor whiteColor];
    [self setupCellUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor whiteColor];
    [self setupCellUI];
  }
  return self;
}

- (void)setupCellUI {
  [self.contentView addSubview:self.arrowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.arrowView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:[self arrowRightMargin]],
    [self.arrowView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.arrowView.widthAnchor constraintEqualToConstant:14.0],
    [self.arrowView.heightAnchor constraintEqualToConstant:14.0],
  ]];

  [self.contentView addSubview:self.avatarView];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
    [self.avatarView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.avatarView.widthAnchor constraintEqualToConstant:[self avatarSize]],
    [self.avatarView.heightAnchor constraintEqualToConstant:[self avatarSize]],
  ]];

  [self.contentView addSubview:self.nameLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameLabel.leftAnchor constraintEqualToAnchor:self.avatarView.rightAnchor constant:12.0],
    [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.nameLabel.rightAnchor constraintEqualToAnchor:self.arrowView.leftAnchor constant:-8.0],
  ]];

  [self.contentView addSubview:self.separator];
  [NSLayoutConstraint activateConstraints:@[
    [self.separator.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
    [self.separator.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.separator.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.separator.heightAnchor constraintEqualToConstant:0.5],
  ]];
}

- (CGFloat)avatarSize {
  return 36.0;
}

- (CGFloat)avatarCornerRadius {
  return 18.0;
}

- (CGFloat)nameFont {
  return 14.0;
}

- (CGFloat)arrowRightMargin {
  return -22.0;
}

- (UIColor *)separatorColor {
  return [UIColor ne_greyLine];
}

- (void)configureBot:(V2NIMUserAIBot *)bot isSelected:(BOOL)isSelected {
  NSString *name = bot.name.length > 0 ? bot.name : (bot.accid ?: @"");
  NSString *shortName = name.length > 2 ? [name substringFromIndex:name.length - 2] : name;
  [self.avatarView configHeadData:bot.icon name:shortName uid:bot.accid ?: @""];
  self.nameLabel.text = name;
  self.arrowView.hidden = isSelected;
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)avatarView {
  if (!_avatarView) {
    _avatarView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _avatarView.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarView.layer.cornerRadius = [self avatarCornerRadius];
    _avatarView.clipsToBounds = YES;
    _avatarView.titleLabel.font = [UIFont systemFontOfSize:14.0];
    _avatarView.titleLabel.textColor = [UIColor whiteColor];
  }
  return _avatarView;
}

- (UILabel *)nameLabel {
  if (!_nameLabel) {
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [UIFont systemFontOfSize:[self nameFont]];
    _nameLabel.textColor = [UIColor ne_darkText];
  }
  return _nameLabel;
}

- (UIImageView *)arrowView {
  if (!_arrowView) {
    _arrowView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    _arrowView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _arrowView;
}

- (UIView *)separator {
  if (!_separator) {
    _separator = [[UIView alloc] init];
    _separator.translatesAutoresizingMaskIntoConstraints = NO;
    _separator.backgroundColor = [self separatorColor];
  }
  return _separator;
}

@end
