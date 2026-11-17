// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/CornerCell.h>
#import "SettingCellModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ChangeType) {
  ChangeTypeTeamName = 0,
  ChangeTypeNickName,
};

typedef NS_ENUM(NSInteger, TeamSettingType) {
  TeamSettingTypeDiscuss = 0,
  TeamSettingTypeSenior = 1,
};

@interface NEBaseTeamSettingCell : CornerCell

@property (nonatomic, strong, nullable) SettingCellModel *model;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *arrowView;

- (void)configure:(id)anyModel;

@end

NS_ASSUME_NONNULL_END
