// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamMemberSelectCell.h"
#import "FunTeamUIColor.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@interface FunTeamMemberSelectCell ()
@property (nonatomic, strong, readwrite) UIView *dividerLine;
@end

@implementation FunTeamMemberSelectCell

- (void)setupUI {
  [super setupUI];
  [self addSubview:self.dividerLine];
  self.headerView.layer.cornerRadius = 4.0;
  self.checkImageView.highlightedImage = [coreLoader() loadImage:@"fun_select"];

  [NSLayoutConstraint activateConstraints:@[
    [self.checkImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.checkImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
    [self.checkImageView.widthAnchor constraintEqualToConstant:22.0],
    [self.checkImageView.heightAnchor constraintEqualToConstant:22.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:54.0],
    [self.headerView.widthAnchor constraintEqualToConstant:40.0],
    [self.headerView.heightAnchor constraintEqualToConstant:40.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.nameStackView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.nameStackView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:105.0],
    [self.nameStackView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.dividerLine.leftAnchor constraintEqualToAnchor:self.headerView.leftAnchor],
    [self.dividerLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.dividerLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.dividerLine.heightAnchor constraintEqualToConstant:1.0],
  ]];
}

- (UIView *)dividerLine {
  if (!_dividerLine) {
    _dividerLine = [[UIView alloc] init];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    _dividerLine.backgroundColor = UIColor.funTeamLineBorderColor;
  }
  return _dividerLine;
}

@end
