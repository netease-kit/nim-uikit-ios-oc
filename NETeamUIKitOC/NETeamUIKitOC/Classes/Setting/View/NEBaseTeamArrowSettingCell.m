// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamArrowSettingCell.h"

@implementation NEBaseTeamArrowSettingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
}

- (void)setupUI {
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.arrowView];
}

@end
