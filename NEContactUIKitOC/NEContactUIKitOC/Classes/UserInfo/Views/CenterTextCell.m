// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "CenterTextCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation CenterTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textColor = [UIColor redColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.accessibilityIdentifier = @"id.titleLabel";
    [self.contentView addSubview:self.titleLabel];
    [NSLayoutConstraint activateConstraints:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36],
      [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
      [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
    self.titleLabel.text = @"title";
    self.line.backgroundColor = [UIColor ne_colorWithHexString:@"#F5F8FC"];
    self.line.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.line];
    [NSLayoutConstraint activateConstraints:@[
      [self.line.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
      [self.line.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
      [self.line.heightAnchor constraintEqualToConstant:1.0],
      [self.line.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (UILabel *)titleLabel {
  if (!_titleLabel) { _titleLabel = [[UILabel alloc] init]; }
  return _titleLabel;
}

- (UIView *)line {
  if (!_line) { _line = [[UIView alloc] init]; }
  return _line;
}

@end
