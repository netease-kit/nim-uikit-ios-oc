// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactUnCheckCell.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation NEBaseContactUnCheckCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupUI {
  [self.contentView addSubview:self.avatarImageView];
}

- (void)configure:(id)model {
  // 具体实现见子类
}

#pragma mark - Lazy Init

- (NEUserHeaderView *)avatarImageView {
  if (!_avatarImageView) {
    _avatarImageView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _avatarImageView.titleLabel.font = [UIFont systemFontOfSize:16.0];
    _avatarImageView.clipsToBounds = YES;
    _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _avatarImageView;
}

@end
