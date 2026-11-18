// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 距离cell边缘的距离
FOUNDATION_EXPORT CGFloat const chat_cell_margin;

/// 控件之间的间距
FOUNDATION_EXPORT CGFloat const chat_content_margin;

/// 头像宽高
FOUNDATION_EXPORT CGFloat const chat_headWH;

/// 时间cell的高度（固定）
FOUNDATION_EXPORT CGFloat const chat_timeCellH;

/// 图片最大宽高
CGSize chat_pic_size(void);

/// 文件宽高
CGSize chat_file_size(void);

/// 单行气泡高度
FOUNDATION_EXPORT CGFloat const chat_min_h;

/// 单行气泡高度(通用版)
FOUNDATION_EXPORT CGFloat const fun_chat_min_h;

/// 回复消息replyLabel高度
FOUNDATION_EXPORT CGFloat const chat_reply_height;

/// 回复消息replyLabel高度(通用版)
FOUNDATION_EXPORT CGFloat const fun_chat_reply_height;

/// 气泡最大宽度 (kScreenWidth - 156)
FOUNDATION_EXPORT CGFloat chat_content_maxW;
#define chat_content_maxW() (chat_content_maxW)

/// 文本内容最大宽度 (chat_content_maxW - 2 * chat_content_margin)
FOUNDATION_EXPORT CGFloat chat_text_maxW;
#define chat_text_maxW() (chat_text_maxW)

/// pin消息需要增加的高度
FOUNDATION_EXPORT CGFloat const chat_pin_height;

/// 群聊气泡上方用户名label高度，p2p无此展示，高度为0
FOUNDATION_EXPORT CGFloat const chat_full_name_height;

/// 语音消息最大宽度
FOUNDATION_EXPORT CGFloat audio_max_width;
#define audio_max_width() (audio_max_width)

/// AI 助聊区域高度
FOUNDATION_EXPORT CGFloat const ai_chat_view_height;

NS_ASSUME_NONNULL_END
