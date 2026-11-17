// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NIMInputSticker.h"

NS_ASSUME_NONNULL_BEGIN

@class InputEmoticonContainerView;

/// 表情容器视图代理（发送按钮 + 表情选择回调）
@protocol InputEmoticonContainerViewDelegate <NSObject>

- (void)selectedEmoticon:(NSString *)emoticonID
           emotCatalogID:(NSString *)emotCatalogID
             description:(NSString *)description;

- (void)didPressSend:(UIButton *)sender;

@optional
- (void)didSelectSticker:(NIMInputSticker *)sticker;

@end

/// 表情输入容器视图（包含分页视图 + Tab 栏）
@interface InputEmoticonContainerView : UIView

@property (nonatomic, weak, nullable) id<InputEmoticonContainerViewDelegate> delegate;
@property (nonatomic, strong) UIColor *accentColor;

- (instancetype)initWithFrame:(CGRect)frame accentColor:(UIColor *)accentColor;

/// Reset the panel to the first built-in emoji page without animation.
- (void)resetToFirstEmojiPage;

@end

NS_ASSUME_NONNULL_END
