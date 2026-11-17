// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NECustomActionSheetController.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SettingCellType) {
  SettingCellTypeSettingArrowCell = 0,
  SettingCellTypeSettingSwitchCell,
  SettingCellTypeSettingSelectCell,
  SettingCellTypeSettingSubtitleSelectCell,
  SettingCellTypeSettingHeaderCell,
  SettingCellTypeSettingTeamUserCell,
  SettingCellTypeSettingSubtitleCell,
  SettingCellTypeSettingSubtitleCustomCell,
};

typedef void (^NESettingSwitchChangeCompletion)(BOOL isOn);
typedef void (^NESettingCellClick)(void);

@interface SettingCellModel : NSObject

@property (nonatomic, copy, nullable) NSString *cellName;
@property (nonatomic, copy, nullable) NSString *subTitle;
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy, nullable) NESettingSwitchChangeCompletion swichChange;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) CGFloat titleWidth;
@property (nonatomic, assign) CornerType cornerType;
@property (nonatomic, copy, nullable) NSString *headerUrl;
@property (nonatomic, copy, nullable) NESettingCellClick cellClick;
@property (nonatomic, assign) BOOL switchOpen;
@property (nonatomic, copy, nullable) NSString *defaultHeadData;
@property (nonatomic, strong, nullable) UIImage *rightCustomViewIcon;
@property (nonatomic, copy, nullable) NESettingCellClick customViewClick;

@end

NS_ASSUME_NONNULL_END
