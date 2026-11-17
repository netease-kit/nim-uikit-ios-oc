// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseFusionContactSelectedCell.h"
#import <NEChatKit/NIMExtension.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/UIColor+NECommon.h>

#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/NEChatKit.h>

@implementation NEBaseFusionContactSelectedCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupFusionSelectedCellUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupFusionSelectedCellUI {
  // UI 初始化，在子类中实现
}

- (void)configFusionModel:(NEFusionContactCellModel *)model {
  if (model.user != nil) {
    self.nameLabel.text = [model.user showName];

    NSString *url = model.user.user.avatar;
    NSString *name = [model.user shortName:YES count:2] ?: @"";
    NSString *accountId = model.user.user.accountId ?: @"";
    [self.userHeaderView configHeadData:url name:name uid:accountId];
  } else if (model.aiUser != nil) {
    self.nameLabel.text = [model getShowName];

    NSString *url = model.aiUser.avatar;
    NSString *name = [model getShortName:2] ?: @"";
    NSString *accountId = model.aiUser.accountId ?: @"";
    [self.userHeaderView configHeadData:url name:name uid:accountId];
  }

  self.selectedStateImage.highlighted = model.selected;
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)userHeaderView {
  if (!_userHeaderView) {
    _userHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _userHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _userHeaderView.clipsToBounds = YES;
    _userHeaderView.titleLabel.font = [NEConstant defaultTextFont:14.0];
    _userHeaderView.userInteractionEnabled = YES;
  }
  return _userHeaderView;
}

- (UILabel *)nameLabel {
  if (!_nameLabel) {
    _nameLabel = [[UILabel alloc] init];
    _nameLabel.textAlignment = NSTextAlignmentLeft;
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [UIFont systemFontOfSize:14.0];
    _nameLabel.textColor = [UIColor ne_colorWithHexString:@"333333"];
    _nameLabel.accessibilityIdentifier = @"id.name";
  }
  return _nameLabel;
}

- (UIImageView *)selectedStateImage {
  if (!_selectedStateImage) {
    _selectedStateImage = [[UIImageView alloc] init];
    _selectedStateImage.image = [coreLoader() loadImage:@"unselect"];
    _selectedStateImage.translatesAutoresizingMaskIntoConstraints = NO;
    _selectedStateImage.accessibilityIdentifier = @"id.selector";
  }
  return _selectedStateImage;
}

- (UIView *)bottomLine {
  if (!_bottomLine) {
    _bottomLine = [[UIView alloc] init];
    _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomLine.hidden = YES;
  }
  return _bottomLine;
}

@end
