// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatCellConstantValue.h"

// 距离cell边缘的距离
CGFloat const chat_cell_margin = 16.0;

// 控件之间的间距
CGFloat const chat_content_margin = 8.0;

// 头像宽高
CGFloat const chat_headWH = 32.0;

// 时间cell的高度（固定）
CGFloat const chat_timeCellH = 22.0;

// 图片最大宽高
CGSize chat_pic_size(void) {
  return CGSizeMake(150.0, 200.0);
}

// 文件宽高
CGSize chat_file_size(void) {
  return CGSizeMake(254.0, 56.0);
}

// 单行气泡高度
CGFloat const chat_min_h = 40.0;

// 单行气泡高度(通用版)
CGFloat const fun_chat_min_h = 42.0;

// 回复消息replyLabel高度
CGFloat const chat_reply_height = 16.0;

// 回复消息replyLabel高度(通用版)
CGFloat const fun_chat_reply_height = 44.0;

CGFloat chat_content_maxW = 0;
CGFloat chat_text_maxW = 0;
CGFloat audio_max_width = 0;

static void NEChatRefreshCellMetrics(void) {
  CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
  chat_content_maxW = screenWidth - 156.0;
  chat_text_maxW = chat_content_maxW - 2.0 * chat_content_margin;
  audio_max_width = screenWidth <= 325.0 ? 230.0 : 265.0;
}

__attribute__((constructor))
static void NEChatInstallCellMetricObserver(void) {
  @autoreleasepool {
    NEChatRefreshCellMetrics();

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    void (^refreshBlock)(NSNotification *) = ^(__unused NSNotification *note) {
      NEChatRefreshCellMetrics();
    };
    [center addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:refreshBlock];
    [center addObserverForName:UIApplicationDidChangeStatusBarFrameNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:refreshBlock];
  }
}

// pin消息需要增加的高度
CGFloat const chat_pin_height = 16.0;

// 群聊气泡上方用户名label高度
CGFloat const chat_full_name_height = 16.0;

// AI 助聊区域高度
CGFloat const ai_chat_view_height = 234.0;
