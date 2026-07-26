// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingSelectCell.h"
#import <NEChatKit/NEConstant.h>

@implementation NEBaseTeamSettingSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  self.subTitleLabel.text = self.model.subTitle;
}

- (void)setupUI {
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.subTitleLabel];
  [self.contentView addSubview:self.arrowView];
}

- (UILabel *)subTitleLabel {
  if (!_subTitleLabel) {
    _subTitleLabel = [[UILabel alloc] init];
    _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subTitleLabel.textColor = [NEConstant hexRGB:0x999999];
    _subTitleLabel.font = [NEConstant defaultTextFont:14.0];
    _subTitleLabel.accessibilityIdentifier = @"id.subTitleValue";
  }
  return _subTitleLabel;
}

@end
