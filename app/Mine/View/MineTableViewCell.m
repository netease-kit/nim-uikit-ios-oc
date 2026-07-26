// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MineTableViewCell.h"
#import "AppKey.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>

@interface MineTableViewCell ()
@property (nonatomic, strong) UIView *bottomLine;
@end

@implementation MineTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setUpSubViews];
  }
  return self;
}

- (void)setUpSubViews {
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  // 图标
  _avatarImageView = [[UIImageView alloc] init];
  _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:_avatarImageView];

  // 标题
  _titleLabel = [[UILabel alloc] init];
  _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _titleLabel.textColor = [UIColor ne_darkText];
  _titleLabel.font = [UIFont systemFontOfSize:16.0];
  _titleLabel.text = NELocalizable(@"setting");
  _titleLabel.accessibilityIdentifier = @"id.titleLabel";
  [self.contentView addSubview:_titleLabel];

  // 分隔线
  _bottomLine = [[UIView alloc] init];
  _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
  _bottomLine.backgroundColor = [UIColor ne_colorWithHexString:@"0xDBE0E8"];
  [self.contentView addSubview:_bottomLine];

  // 箭头
  _arrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
  _arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:_arrowImageView];

  [NSLayoutConstraint activateConstraints:@[
    [_avatarImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
    [_avatarImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [_avatarImageView.widthAnchor constraintEqualToConstant:20],
    [_avatarImageView.heightAnchor constraintEqualToConstant:20],

    [_titleLabel.leftAnchor constraintEqualToAnchor:_avatarImageView.rightAnchor constant:14],
    [_titleLabel.centerYAnchor constraintEqualToAnchor:_avatarImageView.centerYAnchor],

    [_bottomLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
    [_bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [_bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [_bottomLine.heightAnchor constraintEqualToConstant:0.5],

    [_arrowImageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-25],
    [_arrowImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
  ]];
}

- (void)configCellWithData:(NSDictionary<NSString *, NSString *> *)data {
  self.titleLabel.text = data.allKeys.firstObject;
  NSString *imageName = data.allValues.firstObject;
  if (imageName) {
    self.avatarImageView.image = [UIImage imageNamed:imageName];
  }
}

@end
