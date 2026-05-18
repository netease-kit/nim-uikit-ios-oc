// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "MessageEnum.h"

NS_ASSUME_NONNULL_BEGIN

@class NEMoreItemModel;

typedef void (^NEMoreItemAction)(UIViewController *viewController, NEMoreItemModel *_Nullable model);

@interface NEMoreItemModel : NSObject

/// 单元图标
@property (nonatomic, strong, nullable) UIImage *image;

/// 单元名称
@property (nonatomic, copy, nullable) NSString *title;

/// 对应的单元类型
@property (nonatomic, assign) NEMoreActionType type;

/// 动态事件
@property (nonatomic, copy, nullable) NEMoreItemAction action;

/// 自定义图标
@property (nonatomic, strong, nullable) UIImage *customImage;

@end

NS_ASSUME_NONNULL_END
