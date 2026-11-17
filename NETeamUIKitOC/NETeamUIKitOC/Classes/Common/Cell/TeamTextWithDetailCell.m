// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamTextWithDetailCell.h"
#import "TeamDetailItem.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatUIKitOC/ChatCellConstantValue.h>

@implementation TeamTextWithDetailCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _detailTitleLabel = [[UILabel alloc] init];
    _detailTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _detailTitleLabel.font = [UIFont systemFontOfSize:12.0];
    _detailTitleLabel.textColor = [UIColor ne_colorWithHexString:@"#A6ADB6"];
    _detailTitleLabel.textAlignment = NSTextAlignmentJustified;
    _detailTitleLabel.accessibilityIdentifier = @"id.detailTitleLabel";
    [self.contentView addSubview:_detailTitleLabel];

    [NSLayoutConstraint activateConstraints:@[
      [_detailTitleLabel.leftAnchor constraintEqualToAnchor:self.titleLabel.rightAnchor],
      [_detailTitleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
      [_detailTitleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:chat_cell_margin],
      [_detailTitleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-chat_cell_margin],
      [_detailTitleLabel.heightAnchor constraintGreaterThanOrEqualToConstant:36.0],
    ]];
  }
  return self;
}

- (void)setModel:(TeamDetailItem *)model {
  [super setModel:model];
  self.detailTitleLabel.text = model.detailTitle;
}

@end
