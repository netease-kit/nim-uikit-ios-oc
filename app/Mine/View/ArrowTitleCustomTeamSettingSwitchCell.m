// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ArrowTitleCustomTeamSettingSwitchCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "CustomSettingCellModel.h"

@implementation ArrowTitleCustomTeamSettingSwitchCell

- (void)setupUI {
  [super setupUI];
  UIView *backView = self.arrowView.superview;
  if (backView) {
    [backView addSubview:self.selectLabel];
    [NSLayoutConstraint activateConstraints:@[
      [self.selectLabel.rightAnchor constraintEqualToAnchor:self.arrowView.leftAnchor constant:-5],
      [self.selectLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];
  }
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  if ([anyModel isKindOfClass:[CustomSettingCellModel class]]) {
    CustomSettingCellModel *model = (CustomSettingCellModel *)anyModel;
    self.selectLabel.text = model.subTitle;
  }
}

- (UILabel *)selectLabel {
  if (!_selectLabel) {
    _selectLabel = [[UILabel alloc] init];
    _selectLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _selectLabel.textColor = [UIColor ne_colorWithHexString:@"#333333"];
    _selectLabel.font = [UIFont systemFontOfSize:16.0];
    _selectLabel.textAlignment = NSTextAlignmentRight;
  }
  return _selectLabel;
}

@end
