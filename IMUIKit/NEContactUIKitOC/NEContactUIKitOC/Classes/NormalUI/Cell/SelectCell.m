// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SelectCell.h"
#import "NormalContactUIColor.h"
#import "ContactUIConfig.h"
#import "ContactConst.h"
#import <NEChatKit/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>

@implementation SelectCell

/// 重写初始化方法
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.searchTextColor = [UIColor normalContactThemeColor];
  }
  return self;
}

/// 重写初始化方法
- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.searchTextColor = [UIColor normalContactThemeColor];
  }
  return self;
}

/// 重写布局方法
- (void)commonUI {
  [super commonUI];
  self.multiSelectImageView.highlightedImage = [coreLoader() loadImage:@"select"];
}

/// 重写设置文案字体方案
- (void)setConfig {
  [super setConfig];
  CGFloat fontSize = [ContactUIConfig shared].contactProperties.itemTitleSize > 0 ? [ContactUIConfig shared].contactProperties.itemTitleSize : 14;
  self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
}

/// 重写设置头像方法
- (void)setupCommonCircleHeader {
  [super setupCommonCircleHeader];
  self.userHeaderView.layer.cornerRadius = 18;
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:36],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:36],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];
}

@end
