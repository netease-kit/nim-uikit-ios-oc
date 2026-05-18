// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "NEBaseSelectedListCell.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@interface NEBaseSelectedListCell ()
@property (nonatomic, strong, nullable) MultiSelectModel *contentModel;
@end

@implementation NEBaseSelectedListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)commonUI {
  [super commonUI];

  [self.contentView addSubview:self.removeButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.removeButton.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16],
    [self.removeButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.removeButton.heightAnchor constraintEqualToConstant:20],
    [self.removeButton.widthAnchor constraintEqualToConstant:20],
  ]];

  [self.contentView addSubview:self.bottomLine];
  self.bottomLineLeftConstraint = [self.bottomLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:0];
  self.bottomLineLeftConstraint.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1],
  ]];


}

- (void)setConfig {
  [super setConfig];
  self.titleLabel.textColor = [UIColor ne_darkText];
  self.titleLabel.font = [UIFont systemFontOfSize:16];
  self.memberLabelMaxWidth = 56;
  self.optionLabel.font = [UIFont systemFontOfSize:16];
}

- (void)removeButtonAction:(ExpandButton *)sender {
  [self.delegate removeButtonAction:self.contentModel];
}

- (void)setModel:(MultiSelectModel *)model {
  [super setModel:model];
  self.contentModel = model;
  self.multiSelectImageView.hidden = YES;
  if (model.memberCount == 0) {
    self.titleLabelMaxWidth = [UIScreen mainScreen].bounds.size.width - 70 - self.memberLabelMaxWidth;
  } else {
    self.titleLabelMaxWidth = [UIScreen mainScreen].bounds.size.width - 122 - self.memberLabelMaxWidth;
  }
}

#pragma mark - Lazy Init

- (ExpandButton *)removeButton {
  if (!_removeButton) {
    _removeButton = [[ExpandButton alloc] init];
    _removeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_removeButton setImage:[coreLoader() loadImage:@"remove"] forState:UIControlStateNormal];
    [_removeButton addTarget:self action:@selector(removeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    _removeButton.accessibilityIdentifier = @"id.remove";
  }
  return _removeButton;
}

- (UIView *)bottomLine {
  if (!_bottomLine) {
    _bottomLine = [[UIView alloc] init];
    _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomLine.backgroundColor = [UIColor ne_greyLine];
  }
  return _bottomLine;
}

@end
