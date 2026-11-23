// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "NEBaseSelectedListCell.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@interface NEBaseSelectedListCell ()
@property (nonatomic, strong, nullable) MultiSelectModel *contentModel;
- (CGFloat)titleMaxWidthForWidth:(CGFloat)width memberCount:(NSInteger)memberCount;
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
  CGFloat layoutWidth = CGRectGetWidth(self.contentView.bounds);
  if (layoutWidth <= 0) {
    layoutWidth = [UIScreen mainScreen].bounds.size.width;
  }
  self.titleLabelMaxWidth = [self titleMaxWidthForWidth:layoutWidth
                                            memberCount:model.memberCount];
}

/// “已选”列表的标题上限：右侧预留人数与移除按钮的位置。
///
/// 基类在 `layoutSubviews` 里调用本方法；这里覆写以保留“已选”列表自己的预留量。
- (void)recalculateTitleLabelMaxWidth {
  CGFloat width = CGRectGetWidth(self.contentView.bounds);
  if (width <= 0) {
    return;
  }
  CGFloat target = [self titleMaxWidthForWidth:width memberCount:self.contentModel ? self.contentModel.memberCount : 0];
  if (fabs(target - self.titleLabelMaxWidth) <= 0.5) {
    return;
  }
  self.titleLabelMaxWidth = target;
}

- (CGFloat)titleMaxWidthForWidth:(CGFloat)width memberCount:(NSInteger)memberCount {
  CGFloat reserved = memberCount == 0 ? 70 : 122;
  return MAX(0, width - reserved - self.memberLabelMaxWidth);
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
