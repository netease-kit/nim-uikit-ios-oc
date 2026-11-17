// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#pragma mark - DownloadState

/// 下载状态
typedef NS_ENUM(NSInteger, DownloadState) {
  DownloadStateSuccess = 1,
  DownloadStateDownalod, // 注意: 保留原始拼写
};

/// Legacy alias kept for converted OC code paths that still reference the old
/// success symbol while the underlying enum now uses DownloadState.
static const DownloadState FileStateSuccess = DownloadStateSuccess;

#pragma mark - NEMoreActionType

/// 更多面板操作类型
typedef NS_ENUM(NSInteger, NEMoreActionType) {
  NEMoreActionTypeTakePicture = 1,
  NEMoreActionTypeLocation,
  NEMoreActionTypeRtc,
  NEMoreActionTypeGame,
  NEMoreActionTypeFile,
  NEMoreActionTypeRemind,
  NEMoreActionTypePhoto,
  NEMoreActionTypeTranslate,
  NEMoreActionTypeAiChat,
  NEMoreActionTypeOther = 100,
};

#pragma mark - UserSettingType

/// 用户设置类型
typedef NS_ENUM(NSInteger, UserSettingType) {
  UserSettingTypeSwitchType = 1,
  UserSettingTypeSelectType = 2,
};
