// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import "MessageContentModel.h"
#import "UserSettingCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseUserSettingCell : CornerCell

@property (nonatomic, strong, nullable) UserSettingCellModel *model;
@property (nonatomic, assign) CornerType subCornerType;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

- (void)configure:(id)anyModel;

@end

NS_ASSUME_NONNULL_END
