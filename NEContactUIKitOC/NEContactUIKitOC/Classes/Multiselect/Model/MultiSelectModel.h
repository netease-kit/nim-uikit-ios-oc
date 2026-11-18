// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 转发选择页面数据模型
@interface MultiSelectModel : NSObject

// 会话id
@property (nonatomic, copy, nullable) NSString *conversationId;
// 会话名称
@property (nonatomic, copy, nullable) NSString *name;
// 会话头像
@property (nonatomic, copy, nullable) NSString *avatar;
// 无头像时使用的昵称，不使用好友备注
@property (nonatomic, copy, nullable) NSString *avatarName;
// 是否已选中
@property (nonatomic, assign) BOOL isSelected;
// 会话人数
@property (nonatomic, assign) NSInteger memberCount;
// 扩展字段
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *localExtension;

@end

NS_ASSUME_NONNULL_END
