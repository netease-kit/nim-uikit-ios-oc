// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 消息发送状态枚举
typedef NS_ENUM(NSInteger, ChatSendMessageStatus) {
    ChatSendMessageStatusSuccessed = 0,
    ChatSendMessageStatusSending,
    ChatSendMessageStatusFailed,
    ChatSendMessageStatusSendingFailed,  ///< 因反垃圾导致的发送失败
};

@interface ChatActivityIndicatorView : UIView

@property (nonatomic, assign) ChatSendMessageStatus messageStatus;

@property (nonatomic, strong) UIButton *failButton;

@end

NS_ASSUME_NONNULL_END
