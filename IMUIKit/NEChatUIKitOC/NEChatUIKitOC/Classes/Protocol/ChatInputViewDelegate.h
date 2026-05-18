// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// ChatInputViewDelegate.h
// 聊天输入栏代理协议 — 对齐 Swift ChatInputViewDelegate

#import <UIKit/UIKit.h>

@class NEInputMoreCell;

NS_ASSUME_NONNULL_BEGIN

@protocol ChatInputViewDelegate <NSObject>

/// 发送文本消息
/// @param text  纯文本内容
/// @param attribute  富文本内容（含 emoji 等）
- (void)sendText:(NSString *)text attribute:(NSAttributedString *)attribute;

/// 点击底部工具栏按钮（语音、emoji、更多 等）
/// @param button  被点击的按钮
/// @param index   按钮索引
- (void)willSelectItem:(UIButton *)button index:(NSInteger)index;

/// 点击更多面板中的 cell
/// @param cell  被点击的 NEInputMoreCell
- (void)didSelectMoreCell:(NEInputMoreCell *)cell;

/// 文本输入变化回调
/// @param text  当前输入内容
/// @return  是否允许变化
- (BOOL)textChanged:(NSString *)text;

/// 文本删除回调
/// @param range  删除范围
/// @param text   当前文本
/// @return  是否允许删除
- (BOOL)textDelete:(NSRange)range text:(NSString *)text;

/// 开始录音
- (void)startRecord;

/// 录音手势滑出视图
- (void)moveOutView;

/// 录音手势滑入视图
- (void)moveInView;

/// 结束录音
/// @param insideView  结束时手指是否在录音区域内
- (void)endRecord:(BOOL)insideView;

/// 输入框文字变化（UITextField）
- (void)textFieldDidChange:(nullable NSString *)text;

/// 输入框结束编辑
- (void)textFieldDidEndEditing:(nullable NSString *)text;

/// 输入框开始编辑
- (void)textFieldDidBeginEditing:(nullable NSString *)text;

/// 多行模式标题清空回调
- (void)titleTextDidClearEmpty;

/// TextView 内容变化回调
- (void)textViewDidChange;

@end

NS_ASSUME_NONNULL_END
