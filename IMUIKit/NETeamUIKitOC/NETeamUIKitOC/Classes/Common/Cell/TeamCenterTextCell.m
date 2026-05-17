// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamCenterTextCell.h"
#import "TeamDetailItem.h"
#import <NEChatKitOC/UIColor+NECommon.h>

@implementation TeamCenterTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:16.0];
    _titleLabel.textColor = UIColor.redColor;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.accessibilityIdentifier = @"id.titleLabel";
    _titleLabel.text = @"title";
    [self.contentView addSubview:_titleLabel];

    [NSLayoutConstraint activateConstraints:@[
      [_titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36.0],
      [_titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36.0],
      [_titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
      [_titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
      [_titleLabel.heightAnchor constraintGreaterThanOrEqualToConstant:66.0],
    ]];

    _line = [[UIView alloc] init];
    _line.translatesAutoresizingMaskIntoConstraints = NO;
    _line.backgroundColor = [UIColor ne_colorWithHexString:@"#F5F8FC"];
    [self.contentView addSubview:_line];

    [NSLayoutConstraint activateConstraints:@[
      [_line.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
      [_line.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
      [_line.heightAnchor constraintEqualToConstant:1.0],
      [_line.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
  }
  return self;
}

- (void)setModel:(TeamDetailItem *)model {
  self.titleLabel.text = model.title;
  self.titleLabel.textColor = model.textColor;
}

@end
