// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamSettingLabelArrowCell.h"
#import "SettingCellLabelArrowModel.h"
#import <NEChatKit/UIColor+NECommon.h>

@interface FunTeamSettingLabelArrowCell ()
@property (nonatomic, strong, readwrite) UILabel *arrowLabel;
@end

@implementation FunTeamSettingLabelArrowCell

- (void)setupUI {
  [super setupUI];
  [self.contentView addSubview:self.arrowLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.arrowLabel.centerYAnchor constraintEqualToAnchor:self.arrowView.centerYAnchor],
    [self.arrowLabel.rightAnchor constraintEqualToAnchor:self.arrowView.leftAnchor constant:-4.0],
  ]];
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  if ([anyModel isKindOfClass:[SettingCellLabelArrowModel class]]) {
    self.arrowLabel.text = ((SettingCellLabelArrowModel *)anyModel).arrowLabelText;
  }
}

- (UILabel *)arrowLabel {
  if (!_arrowLabel) {
    _arrowLabel = [[UILabel alloc] init];
    _arrowLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _arrowLabel.textColor = UIColor.ne_lightText;
    _arrowLabel.font = [UIFont systemFontOfSize:16.0];
    _arrowLabel.textAlignment = NSTextAlignmentRight;
  }
  return _arrowLabel;
}

@end
