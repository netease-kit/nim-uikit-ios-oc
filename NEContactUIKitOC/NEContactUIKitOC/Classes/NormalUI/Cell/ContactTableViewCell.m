// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactTableViewCell.h"
#import "ContactInfo.h"
#import "ContactUIConfig.h"
#import "NormalContactUIColor.h"
#import "ContactConst.h"

@implementation ContactTableViewCell

- (void)setConfig {
  [super setConfig];
  CGFloat fontSize = [ContactUIConfig shared].contactProperties.itemTitleSize > 0 ? [ContactUIConfig shared].contactProperties.itemTitleSize : 14;
  self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
}

- (void)commonUI {
  [super commonUI];
  self.backgroundColor = [UIColor normalContactItemBackgroundColor];
  self.bottomLine.backgroundColor = [UIColor normalContactItemLineBackgroundColor];
}

- (void)setupCommonCircleHeader {
  [super setupCommonCircleHeader];
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:36],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:36],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];
}

- (void)setModel:(ContactInfo *)model {
  [super setModel:model];
  if (model.contactCellType == ContactCellTypeContactPerson) {
    self.bottomLine.hidden = YES;
  }
}

@end
