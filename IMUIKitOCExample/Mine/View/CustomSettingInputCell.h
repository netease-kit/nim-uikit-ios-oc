// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NETeamUIKitOC/TeamSettingSubtitleCell.h>
#import "CustomSettingCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CustomSettingInputCell : TeamSettingSubtitleCell <UITextFieldDelegate>

@property(nonatomic, strong) UITextField *inputTextField;
@property(nonatomic, weak, nullable) CustomSettingCellModel *dataModel;

@end

NS_ASSUME_NONNULL_END
