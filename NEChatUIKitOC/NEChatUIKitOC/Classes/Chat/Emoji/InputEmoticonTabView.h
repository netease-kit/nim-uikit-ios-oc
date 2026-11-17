// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NIMInputEmoticonManager.h"

NS_ASSUME_NONNULL_BEGIN

@class InputEmoticonTabView;

/// 表情底部 Tab 视图代理
@protocol InputEmoticonTabViewDelegate <NSObject>

@optional
- (void)tabView:(nullable InputEmoticonTabView *)tabView didSelectTabIndex:(NSInteger)index;

@end

/// 表情底部 Tab 栏（发送按钮 + 分类切换）
@interface InputEmoticonTabView : UIControl

@property (nonatomic, weak, nullable) id<InputEmoticonTabViewDelegate> delegate;

/// 发送按钮
@property (nonatomic, strong) UIButton *sendButton;

/// 选中指定索引的 Tab
- (void)selectTabIndex:(NSInteger)index;

/// 根据分类数据加载 Tab
- (void)loadCatalogs:(nullable NSArray<NIMInputEmoticonCatalog *> *)emoticonCatalogs;

@end

NS_ASSUME_NONNULL_END
