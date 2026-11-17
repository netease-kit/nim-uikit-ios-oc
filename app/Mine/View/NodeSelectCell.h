// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/CornerCell.h>
#import <NETeamUIKitOC/SettingCellModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface NodeSelectCell : CornerCell

@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIImageView *stateImageView;

- (void)configureWithModel:(SettingCellModel *)cellModel;

@end

NS_ASSUME_NONNULL_END
