// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "TextWithDetailTextCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation TextWithDetailTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.detailTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.detailTitleLabel.font = [UIFont systemFontOfSize:12];
    self.detailTitleLabel.textColor = [UIColor ne_colorWithHexString:@"#A6ADB6"];
    self.detailTitleLabel.textAlignment = NSTextAlignmentRight;
    self.detailTitleLabel.accessibilityIdentifier = @"id.detailTitleLabel";
    [self.contentView addSubview:self.detailTitleLabel];
    [NSLayoutConstraint activateConstraints:@[
      [self.detailTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
      [self.detailTitleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
      [self.detailTitleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
      [self.detailTitleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (UILabel *)detailTitleLabel {
  if (!_detailTitleLabel) { _detailTitleLabel = [[UILabel alloc] init]; }
  return _detailTitleLabel;
}

@end
