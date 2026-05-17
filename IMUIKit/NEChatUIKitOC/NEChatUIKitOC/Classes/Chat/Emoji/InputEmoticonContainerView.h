// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class InputEmoticonContainerView;

/// 表情容器视图代理（发送按钮 + 表情选择回调）
@protocol InputEmoticonContainerViewDelegate <NSObject>

- (void)selectedEmoticon:(NSString *)emoticonID
           emotCatalogID:(NSString *)emotCatalogID
             description:(NSString *)description;

- (void)didPressSend:(UIButton *)sender;

@end

/// 表情输入容器视图（包含分页视图 + Tab 栏）
@interface InputEmoticonContainerView : UIView

@property (nonatomic, weak, nullable) id<InputEmoticonContainerViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
