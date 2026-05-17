// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingSwitchCell.h"

@implementation NEBaseTeamSettingSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  self.tSwitch.on = self.model.switchOpen;
}

- (void)setupUI {
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.tSwitch];
  [self.tSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)switchChange:(UISwitch *)sender {
  if (self.model.swichChange) {
    self.model.swichChange(sender.on);
  }
}

- (UISwitch *)tSwitch {
  if (!_tSwitch) {
    _tSwitch = [[UISwitch alloc] init];
    _tSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    _tSwitch.accessibilityIdentifier = @"id.tSwitch";
  }
  return _tSwitch;
}

@end
