// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEGrowingTextView;

@protocol NEGrowingTextViewDelegate <NSObject>

@optional
/// 变高输入框是否开始编辑回调
- (BOOL)growingTextViewShouldBeginEditing:(NEGrowingTextView *)growingTextView;
/// 变高输入框是否结束编辑回调
- (BOOL)growingTextViewShouldEndEditing:(NEGrowingTextView *)growingTextView;
/// 变高输入框开始编辑回调
- (void)growingTextViewDidBeginEditing:(NEGrowingTextView *)growingTextView;
/// 变高输入框结束编辑回调
- (void)growingTextViewDidEndEditing:(NEGrowingTextView *)growingTextView;
/// 变高输入框文字变化前回调
- (BOOL)growingTextView:(NEGrowingTextView *)growingTextView
  shouldChangeTextInRange:(NSRange)range
          replacementText:(NSString *)text;
/// 变高输入框文字变化回调
- (void)growingTextViewDidChange:(NEGrowingTextView *)growingTextView;
/// 变高输入框选区变化回调
- (void)growingTextViewDidChangeSelection:(NEGrowingTextView *)growingTextView;
/// 变高输入框高度将要变化回调
- (void)growingTextView:(NEGrowingTextView *)growingTextView
       willChangeHeight:(CGFloat)height
             difference:(CGFloat)difference;
/// 变高输入框高度变化回调
- (void)growingTextView:(NEGrowingTextView *)growingTextView
        didChangeHeight:(CGFloat)height
             difference:(CGFloat)difference;
/// 变高输入框点击 return 回调
- (BOOL)growingTextViewShouldReturn:(NEGrowingTextView *)growingTextView;

@end

NS_ASSUME_NONNULL_END
