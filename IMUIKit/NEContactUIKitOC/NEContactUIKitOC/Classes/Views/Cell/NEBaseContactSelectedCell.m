// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactSelectedCell.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import "ContactInfo.h"

@implementation NEBaseContactSelectedCell

- (void)commonUI {
  [super commonUI];
  self.leftConstraint.constant = 50;
  [self.contentView addSubview:self.sImageView];
  self.sImageView.image = [coreLoader() loadImage:@"unselect"];
  self.sImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.sImageView.accessibilityIdentifier = @"id.selector";
}

- (void)setModel:(ContactInfo *)model {
  [super setModel:model];
  self.sImageView.highlighted = model.isSelected;
}

#pragma mark - Lazy Init

- (UIImageView *)sImageView {
  if (!_sImageView) {
    _sImageView = [[UIImageView alloc] init];
  }
  return _sImageView;
}

@end
