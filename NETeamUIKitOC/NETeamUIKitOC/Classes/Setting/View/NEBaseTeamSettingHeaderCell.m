// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingHeaderCell.h"
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@implementation NEBaseTeamSettingHeaderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  NSString *url = self.model.headerUrl;
  NSString *name = self.model.defaultHeadData ?: @"";
  NSString *accountId = self.model.subTitle ?: @"";
  [self.headerView configHeadData:url name:name uid:accountId];
}

- (void)setupUI {
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.arrowView];
  [self.contentView addSubview:self.headerView];
}

- (NEUserHeaderView *)headerView {
  if (!_headerView) {
    _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.clipsToBounds = YES;
  }
  return _headerView;
}

@end
