// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingCell.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/NEConstant.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>

@implementation NEBaseTeamSettingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.backgroundColor = UIColor.clearColor;
    self.showDefaultLine = YES;
  }
  return self;
}

- (void)configure:(id)anyModel {
  if ([anyModel isKindOfClass:[SettingCellModel class]]) {
    SettingCellModel *model = (SettingCellModel *)anyModel;
    self.model = model;
    self.cornerType = model.cornerType;
    self.titleLabel.text = model.cellName;
  }
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.textColor = [NEConstant hexRGB:0x333333];
    _titleLabel.font = [NEConstant defaultTextFont:16.0];
    _titleLabel.accessibilityIdentifier = @"id.titleLabel";
  }
  return _titleLabel;
}

- (UIImageView *)arrowView {
  if (!_arrowView) {
    _arrowView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _arrowView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _arrowView;
}

@end
