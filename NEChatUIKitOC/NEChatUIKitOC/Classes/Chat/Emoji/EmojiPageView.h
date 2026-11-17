// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class EmojiPageView;

/// 表情分页视图数据源
@protocol EmojiPageViewDataSource <NSObject>

@optional
- (NSInteger)numberOfPages:(nullable EmojiPageView *)pageView;
- (UIView *)pageView:(nullable EmojiPageView *)pageView index:(NSInteger)index;

@end

/// 表情分页视图代理
@protocol EmojiPageViewDelegate <NSObject>

@optional
- (void)pageViewScrollEnd:(nullable EmojiPageView *)pageView
             currentIndex:(NSInteger)currentIndex
               totolPages:(NSInteger)totolPages;

- (void)pageViewDidScroll:(nullable EmojiPageView *)pageView;

- (BOOL)needScrollAnimation;

@end

/// 横向分页滚动视图（表情面板专用）
@interface EmojiPageView : UIView

@property (nonatomic, weak, nullable) id<EmojiPageViewDataSource> dataSource;
@property (nonatomic, weak, nullable) id<EmojiPageViewDelegate> pageViewDelegate;

/// 滚动到指定页
- (void)scrollToPage:(NSInteger)page;

/// 重新加载数据
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
