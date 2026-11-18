// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTableViewCell.h"

@interface NEBaseTableViewCell ()
@property (nonatomic, strong, readwrite) UIView *separatorLine;
@property (nonatomic, strong) NSLayoutConstraint *separatorLeftConstraint;
@end

@implementation NEBaseTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _separatorInsetLeft = 16.0;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self buildSeparatorLine];
    [self setupSubviews];
  }
  return self;
}

- (void)buildSeparatorLine {
  _separatorLine = [[UIView alloc] init];
  _separatorLine.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
  _separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:_separatorLine];

  _separatorLeftConstraint = [_separatorLine.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:_separatorInsetLeft];
  [NSLayoutConstraint activateConstraints:@[
    _separatorLeftConstraint,
    [_separatorLine.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
    [_separatorLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [_separatorLine.heightAnchor constraintEqualToConstant:0.5],
  ]];
}

- (void)setupSubviews {
  // 子类重写
}

+ (NSString *)reuseId {
  return NSStringFromClass(self);
}

#pragma mark - Setters

- (void)setSeparatorInsetLeft:(CGFloat)separatorInsetLeft {
  _separatorInsetLeft = separatorInsetLeft;
  _separatorLeftConstraint.constant = separatorInsetLeft;
}

- (void)setSeparatorHidden:(BOOL)separatorHidden {
  _separatorHidden = separatorHidden;
  _separatorLine.hidden = separatorHidden;
}

@end
