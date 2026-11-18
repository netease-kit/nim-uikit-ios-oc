// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunContactTableViewCell.h"
#import "FunContactUIColor.h"
#import "ContactUIConfig.h"
#import "ContactConst.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation FunContactTableViewCell

- (void)setupCommonCircleHeader {
  [super setupCommonCircleHeader];
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:40],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:40],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];
}

- (void)commonUI {
  [super commonUI];
  self.backgroundColor = [UIColor funContactItemBackgroundColor];
  self.bottomLine.backgroundColor = [UIColor funContactItemLineBackgroundColor];

  [self.redAngleView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-10].active = YES;
}

- (void)initSubviewsLayout {
  if ([ContactUIConfig shared].contactProperties.avatarType == NEContactAvatarTypeCycle) {
    self.userHeaderView.layer.cornerRadius = 20.0;
  } else if ([ContactUIConfig shared].contactProperties.avatarCornerRadius > 0) {
    self.userHeaderView.layer.cornerRadius = [ContactUIConfig shared].contactProperties.avatarCornerRadius;
  } else {
    self.userHeaderView.layer.cornerRadius = 4.0; // Fun UI
  }
}

- (void)setConfig {
  [super setConfig];
  CGFloat fontSize = [ContactUIConfig shared].contactProperties.itemTitleSize > 0 ? [ContactUIConfig shared].contactProperties.itemTitleSize : 17;
  self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
}

- (void)setModel:(ContactInfo *)model {
  [super setModel:model];
  self.arrowImageView.hidden = YES;
}

@end
