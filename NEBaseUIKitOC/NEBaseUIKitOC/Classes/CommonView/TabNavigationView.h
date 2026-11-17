// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class ExpandButton;

NS_ASSUME_NONNULL_BEGIN

@protocol TabNavigationViewDelegate <NSObject>
@optional
- (void)didClickAddBtn;
- (void)searchAction;
- (void)brandBtnClick;
@end

/// 首页导航栏视图（含品牌按钮、搜索按钮、添加按钮）
@interface TabNavigationView : UIView

@property (nonatomic, weak, nullable) id<TabNavigationViewDelegate> delegate;
@property (nonatomic, assign) double titleBarBottomLineHeight; ///< 默认 0.5

@property (nonatomic, strong) UIButton *brandBtn;
@property (nonatomic, strong) UILabel *navigationTitle;
@property (nonatomic, strong) UIButton *searchBtn;
@property (nonatomic, strong) ExpandButton *addBtn;
@property (nonatomic, strong) UIView *titleBarView;
@property (nonatomic, strong) UIView *titleBarBottomLine;

- (void)setupSubviews;
- (void)brandBtnClick:(UIButton *)sender;
- (void)searchBtnClickWithSender:(UIButton *)sender;
- (void)addBtnClickWithSender:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
