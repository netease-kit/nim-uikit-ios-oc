// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import "NEContactBaseViewController.h"
#import "NEBaseFusionContactSelectedController.h"
#import "NEFusionContactCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@class NEPagingViewController;

@interface NEBaseContactSelectedPageController : NEContactBaseViewController <FusionContactSelectedDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

/// 选择数量限制
@property (nonatomic, assign) NSInteger limit;

/// page view 视图控制器
@property (nonatomic, strong) NSMutableArray<NEBaseFusionContactSelectedController *> *childrenControllers;

/// 选择确定按钮
@property (nonatomic, strong) UIButton *selectedSureButton;

@property (nonatomic, copy, nullable) NSString *userId;

/// 内容controller集合
@property (nonatomic, strong) NSMutableArray<NEBaseFusionContactSelectedController *> *contentControllers;

/// 选择记录
@property (nonatomic, strong) NSMutableArray<NEFusionContactCellModel *> *selectArray;

/// 显示选中背景
@property (nonatomic, strong) UIView *selectCollectionBackView;

/// 显示选中列表
@property (nonatomic, strong) UICollectionView *selectCollectionView;

@property (nonatomic, assign) CGFloat collectionBackViewTopMargin;
@property (nonatomic, assign) CGFloat collectionBackViewHeight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *collectionBackViewTopAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *pagingViewControllerTopAnchor;
@property (nonatomic, strong, nullable) NEPagingViewController *pagingViewController;

- (instancetype)initWithFilterUsers:(nullable NSSet<NSString *> *)filterUsers;

- (nullable NSArray<NEBaseFusionContactSelectedController *> *)getContentControllers:(nullable NSSet<NSString *> *)filterUsers;
- (void)setupPageContent;
- (void)setupNavSureItem;
- (void)selectSureClick:(UIButton *)sender;

- (BOOL)didSelectedUser:(NEFusionContactCellModel *)model;
- (void)didUnselectedUser:(NEFusionContactCellModel *)model;
- (void)didChangeSelectUser;
- (void)didUnselect:(NEFusionContactCellModel *)model;

@end

NS_ASSUME_NONNULL_END
