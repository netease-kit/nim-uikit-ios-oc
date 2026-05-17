// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "NEBaseSelectedCell.h"
#import <NIMSDK/NIMSDK.h>

@implementation NEBaseSelectedCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  [self.contentView addSubview:self.avatarImageView];
  self.avatarImageView.layer.cornerRadius = 16;
  self.avatarImageView.titleLabel.font = [UIFont systemFontOfSize:12.0];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.avatarImageView.widthAnchor constraintEqualToConstant:32],
    [self.avatarImageView.heightAnchor constraintEqualToConstant:32],
  ]];
}

- (void)configure:(id)model {
  if (![model isKindOfClass:[MultiSelectModel class]]) return;
  MultiSelectModel *m = (MultiSelectModel *)model;
  [self.avatarImageView configHeadData:m.avatar
                                  name:m.name ?: @""
                                   uid:[V2NIMConversationIdUtil conversationTargetId:m.conversationId ?: @""] ?: @""];
}

- (NEUserHeaderView *)avatarImageView {
  if (!_avatarImageView) {
    _avatarImageView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarImageView.clipsToBounds = YES;
  }
  return _avatarImageView;
}

@end
