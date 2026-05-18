// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamDefaultIconCell.h"
#import <NEChatKitOC/NEConstant.h>

@implementation NEBaseTeamDefaultIconCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setSelected:(BOOL)selected {
  [super setSelected:selected];
  NSLog(@"default icon select %d", selected);
  self.selectBackView.hidden = !selected;
}

- (void)setupUI {
  [self.contentView addSubview:self.selectBackView];
  [self.contentView addSubview:self.iconImageView];
}

- (UIImageView *)iconImageView {
  if (!_iconImageView) {
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
  }
  return _iconImageView;
}

- (UIView *)selectBackView {
  if (!_selectBackView) {
    _selectBackView = [[UIView alloc] init];
    _selectBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _selectBackView.backgroundColor = [NEConstant hexRGB:0xF4F4F4];
    _selectBackView.clipsToBounds = YES;
    _selectBackView.layer.cornerRadius = 8.0;
    _selectBackView.hidden = YES;
  }
  return _selectBackView;
}

@end
