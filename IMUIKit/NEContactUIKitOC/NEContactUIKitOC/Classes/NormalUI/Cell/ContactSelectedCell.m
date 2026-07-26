// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactSelectedCell.h"
#import "ContactUIConfig.h"
#import "ContactConst.h"
#import <NEChatKit/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>

@implementation ContactSelectedCell

- (void)commonUI {
  [super commonUI];
  self.sImageView.highlightedImage = [coreLoader() loadImage:@"select"];
  [NSLayoutConstraint activateConstraints:@[
    [self.sImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.sImageView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
  ]];
}

- (void)setConfig {
  [super setConfig];
  CGFloat fontSize = [ContactUIConfig shared].contactProperties.itemTitleSize > 0 ? [ContactUIConfig shared].contactProperties.itemTitleSize : 14;
  self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
}

- (void)setupCommonCircleHeader {
  [super setupCommonCircleHeader];
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:36],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:36],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0],
  ]];
}

@end
