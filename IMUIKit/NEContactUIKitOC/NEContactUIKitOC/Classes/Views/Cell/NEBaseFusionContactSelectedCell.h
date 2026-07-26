// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "NEFusionContactCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseFusionContactSelectedCell : UITableViewCell

/// 用户头像
@property (nonatomic, strong) NEUserHeaderView *userHeaderView;
/// 用户名展示标签
@property (nonatomic, strong) UILabel *nameLabel;
/// 选中图片
@property (nonatomic, strong) UIImageView *selectedStateImage;
/// 分隔线
@property (nonatomic, strong) UIView *bottomLine;

- (void)setupFusionSelectedCellUI;
- (void)configFusionModel:(NEFusionContactCellModel *)model;

@end

NS_ASSUME_NONNULL_END
