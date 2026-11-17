// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NIMInputEmoticonManager.h"

NS_ASSUME_NONNULL_BEGIN

/// 表情富文本附件（NSTextAttachment 子类）
@interface NEEmotionAttachment : NSTextAttachment

/// 关联的表情数据（设置时自动加载图片）
@property (nonatomic, strong, nullable) NIMInputEmoticon *emotion;

@end

NS_ASSUME_NONNULL_END
