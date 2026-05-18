// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "ContactBaseTextCell.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation ContactBaseTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = [UIFont systemFontOfSize:16];
    self.titleLabel.textColor = [UIColor ne_colorWithHexString:@"#333333"];
    [self.contentView addSubview:self.titleLabel];
    [NSLayoutConstraint activateConstraints:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
      [self.titleLabel.widthAnchor constraintEqualToConstant:90],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
      [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
    self.titleLabel.text = @"";

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

- (void)setModelWithModel:(UserItem *)model {
  self.titleLabel.text = model.title;
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
