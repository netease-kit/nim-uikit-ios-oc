// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "RecentSelectCell.h"
#import "MultiSelectModel.h"
#import "ContactConst.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>

@implementation RecentSelectCell

/// 重写布局方法
- (void)setupUI {
  [super setupUI];
  [self setAvatarWH:36];
}

/// 重写控件赋值方法
- (void)configure:(id)model {
  if (![model isKindOfClass:[MultiSelectModel class]]) return;
  MultiSelectModel *selectModel = (MultiSelectModel *)model;

  [super configure:selectModel];
  self.selectImageView.image = selectModel.isSelected ? [coreLoader() loadImage:@"select"] : [coreLoader() loadImage:@"unselect"];
}

@end
