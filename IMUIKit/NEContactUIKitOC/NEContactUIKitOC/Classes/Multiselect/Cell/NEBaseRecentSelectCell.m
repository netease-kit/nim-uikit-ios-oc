// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "NEBaseRecentSelectCell.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation NEBaseRecentSelectCell

- (void)setupUI {
  [self.contentView addSubview:self.avatarImageView];
  self.avatarImageView.layer.cornerRadius = 18;
  self.avatarImageView.titleLabel.font = [UIFont systemFontOfSize:16.0];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.avatarImageView.widthAnchor constraintEqualToConstant:36],
    [self.avatarImageView.heightAnchor constraintEqualToConstant:36],
  ]];

  [self.contentView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:8],
    [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.avatarImageView.centerXAnchor],
    [self.titleLabel.widthAnchor constraintEqualToConstant:72],
    [self.titleLabel.heightAnchor constraintEqualToConstant:16],
  ]];

  [self.contentView addSubview:self.selectImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.selectImageView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6],
    [self.selectImageView.centerXAnchor constraintEqualToAnchor:self.avatarImageView.centerXAnchor],
    [self.selectImageView.widthAnchor constraintEqualToConstant:18],
    [self.selectImageView.heightAnchor constraintEqualToConstant:18],
  ]];
}

- (void)setAvatarWH:(CGFloat)height {
  self.avatarImageView.layer.cornerRadius = height / 2;


}

- (void)showSelect:(BOOL)isShow {
  self.selectImageView.hidden = !isShow;
}

- (void)configure:(id)model {
  if (![model isKindOfClass:[MultiSelectModel class]]) return;
  MultiSelectModel *m = (MultiSelectModel *)model;
  [super configure:model];
  self.titleLabel.text = m.name;
}

#pragma mark - Lazy Init

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.textColor = [UIColor ne_darkText];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont systemFontOfSize:12];
    _titleLabel.accessibilityIdentifier = @"id.name";
  }
  return _titleLabel;
}

- (UIImageView *)selectImageView {
  if (!_selectImageView) {
    _selectImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"unselect"]];
    _selectImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _selectImageView;
}

@end
