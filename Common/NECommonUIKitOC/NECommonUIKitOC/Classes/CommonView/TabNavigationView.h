// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TabNavigationViewDelegate <NSObject>
@optional
- (void)brandBtnClick;
- (void)didClickAddBtn;
- (void)searchAction;
@end

/// 首页导航栏视图（含品牌按钮、搜索按钮、添加按钮）
@interface TabNavigationView : UIView

@property (nonatomic, weak, nullable) id<TabNavigationViewDelegate> delegate;
@property (nonatomic, assign) CGFloat titleBarBottomLineHeight; ///< 默认 0.5

@property (nonatomic, strong, readonly) UIButton *brandBtn;
@property (nonatomic, strong, readonly) UILabel *navigationTitle;
@property (nonatomic, strong, readonly) UIButton *searchBtn;
@property (nonatomic, strong, readonly) UIButton *addBtn;
@property (nonatomic, strong, readonly) UIView *titleBarView;
@property (nonatomic, strong, readonly) UIView *titleBarBottomLine;

- (void)setupSubviews;

@end

NS_ASSUME_NONNULL_END
