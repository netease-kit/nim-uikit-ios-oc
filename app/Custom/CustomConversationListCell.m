// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomConversationListCell.h"
#import <NECommonUIKitOC/NEUserHeaderView.h>

@interface CustomConversationListCell ()
@property (nonatomic, strong) UIImageView *customBadgeView;
@end

@implementation CustomConversationListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _customBadgeView = [[UIImageView alloc] init];
    _customBadgeView.translatesAutoresizingMaskIntoConstraints = NO;
    _customBadgeView.image = [UIImage imageNamed:@"about_yunxin"];
    [self.contentView addSubview:_customBadgeView];
    [NSLayoutConstraint activateConstraints:@[
      [_customBadgeView.leftAnchor constraintEqualToAnchor:self.headImageView.leftAnchor],
      [_customBadgeView.bottomAnchor constraintEqualToAnchor:self.headImageView.bottomAnchor],
      [_customBadgeView.widthAnchor constraintEqualToConstant:12],
      [_customBadgeView.heightAnchor constraintEqualToConstant:12],
    ]];
  }
  return self;
}

- (void)configureData:(NEConversationListModel *)model {
  [super configureData:model];
}

@end
