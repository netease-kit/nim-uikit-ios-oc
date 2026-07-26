// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunSelectCell.h"
#import "ContactConst.h"
#import <NEChatKit/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation FunSelectCell

/// 重写初始化方法
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.searchTextColor = [UIColor colorWithRed:0.2 green:0.72 blue:0.66 alpha:1.0];
  }
  return self;
}

/// 重写初始化方法
- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.searchTextColor = [UIColor colorWithRed:0.2 green:0.72 blue:0.66 alpha:1.0];
  }
  return self;
}

/// 重写布局方法
- (void)commonUI {
  [super commonUI];
  self.multiSelectImageView.highlightedImage = [coreLoader() loadImage:@"fun_select"];
}

/// 重写设置文案字体方案
- (void)setConfig {
  [super setConfig];
  self.titleLabel.font = [UIFont systemFontOfSize:16];
  self.optionLabel.font = [UIFont systemFontOfSize:16];
  self.memberLabelMaxWidth = 56;
}

/// 重写设置头像方法
- (void)setupCommonCircleHeader {
  [super setupCommonCircleHeader];
  self.userHeaderView.layer.cornerRadius = 4;
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:40],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:40],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];
}

@end
