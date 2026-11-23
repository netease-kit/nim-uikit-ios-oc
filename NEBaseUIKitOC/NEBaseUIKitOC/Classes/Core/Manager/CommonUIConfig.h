// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 图片选择完成回调；取消或失败时回传 nil。
typedef void (^NECommonPhotoPickerCompletion)(UIImage *_Nullable image);

/// 第三方图片选择器桥：`presenter` 发起选择的页面，`limit` 为最多可选数量。
/// 由宿主注入具体实现（如 ZLPhotoBrowser）；未注入时页面沿用系统相册兜底。
typedef void (^NECommonPhotoPickerHandler)(UIViewController *presenter,
                                           NSInteger limit,
                                           NECommonPhotoPickerCompletion completion);

/// CommonUIKit 全局 UI 配置单例
@interface CommonUIConfig : NSObject

@property (nonatomic, class, readonly) CommonUIConfig *shared;

/// 导航栏返回按钮图片
@property (nonatomic, strong, nullable) UIImage *backArrowImage;

/// 第三方图片选择器桥：`NEContactUIKitOC`、`NETeamUIKitOC` 等 UI 模块不依赖消息 UI，
/// 但都需要“从相册选一张图”（机器人头像、群头像等）。由宿主注入具体实现，
/// 页面只消费该回调；未注入（nil）时沿用系统 `UIImagePickerController` 兜底。
@property (nonatomic, copy, nullable) NECommonPhotoPickerHandler photoPickerHandler;

@end

NS_ASSUME_NONNULL_END