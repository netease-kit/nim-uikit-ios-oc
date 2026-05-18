// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import "NEContactBaseViewController.h"
#import "ContactViewModel.h"
#import "ContactConst.h"

@class NEBaseContactTableViewCell;
@class ContactSectionView;

NS_ASSUME_NONNULL_BEGIN

/// 人员选择页面 - 基类
@interface NEBaseContactSelectedViewController : NEContactBaseViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy, nullable) ContactsSelectCompletion callBack;
@property (nonatomic, strong, nullable) NSSet<NSString *> *filterUsers;
@property (nonatomic, assign) NSInteger limit;

/// 单聊中对方的userId
@property (nonatomic, copy, nullable) NSString *userId;

@property (nonatomic, strong) NSMutableArray<ContactInfo *> *selectArray;
@property (nonatomic, assign) BOOL isCreating;

@property (nonatomic, strong, nullable) NSLayoutConstraint *collectionBackViewTopAnchor;
@property (nonatomic, strong) UIView *collectionBackView;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *sureButton;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *customCells;
@property (nonatomic, strong) ContactViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

- (instancetype)initWithFilterUsers:(nullable NSSet<NSString *> *)filterUsers;

- (void)setupUI;
- (void)loadData;
- (void)setupNavRightItem;
- (void)sureClick:(UIButton *)sender;
- (void)didSelectContact:(ContactInfo *)contact;
- (void)didUnselectContact:(ContactInfo *)contact;
- (void)refreshSelectCount;

@end

NS_ASSUME_NONNULL_END
