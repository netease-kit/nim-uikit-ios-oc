// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEUnifiedBackButton.h>
#import "NEContactBaseViewController.h"
#import "MultiSelectViewModel.h"
#import "MultiSelectModel.h"
#import "NEBaseSelectCell.h"
#import "NEBaseSelectedCell.h"
#import "NEBaseRecentSelectCell.h"
#import "NEBaseMultiSelectedViewController.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseMultiSelectViewController : NEContactBaseViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, NEBaseMultiSelectedViewControllerDelegate>

@property (nonatomic, strong, readonly) MultiSelectViewModel *viewModel;
@property (nonatomic, strong, nullable) NSSet<NSString *> *filterUsers;
@property (nonatomic, assign) NSInteger limit;
@property (nonatomic, copy, nullable) NSString *userId;
@property (nonatomic, strong) NSMutableArray<MultiSelectModel *> *selectedArray;
@property (nonatomic, strong) NSMutableArray<MultiSelectModel *> *recentArray;
@property (nonatomic, assign) NSInteger tabIndex;
@property (nonatomic, assign) BOOL isMultiSelect;
@property (nonatomic, assign) BOOL usesAdaptiveContainerPresentation;
@property (nonatomic, copy, nullable) NSString *searchText;
@property (nonatomic, weak, nullable) UITableView *currentTableView;

@property (nonatomic, assign) CGFloat selectedContentViewHeight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *selectedContentViewHeightAnchor;
@property (nonatomic, assign) CGFloat recentContentViewHeight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *recentContentViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *selectedLineLeftAnchor;

@property (nonatomic, strong) UIColor *themeColor;
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *sureButtonText;

// UI
@property (nonatomic, strong) SearchTextField *searchTextField;
@property (nonatomic, strong) UIView *selectedContentView;
@property (nonatomic, strong) UICollectionView *selectedCollectionView;
@property (nonatomic, strong) UIView *recentContentView;
@property (nonatomic, strong) UICollectionView *recentCollectionView;
@property (nonatomic, strong) UIView *tabContentView;
@property (nonatomic, strong) UITableView *recentTableView;
@property (nonatomic, strong) UITableView *friendTableView;
@property (nonatomic, strong) UITableView *teamTableView;
@property (nonatomic, strong) UIView *tableViewContentView;
@property (nonatomic, strong) UIView *sessionContentView;
@property (nonatomic, strong) NEUnifiedBackButton *cancelButton;
@property (nonatomic, strong) ExpandButton *multiSelectButton;
@property (nonatomic, strong) ExpandButton *sureButton;
@property (nonatomic, strong) UIButton *recentButton;
@property (nonatomic, strong) UIButton *friendButton;
@property (nonatomic, strong) UIButton *teamButton;

- (instancetype)initWithFilterUsers:(nullable NSSet<NSString *> *)filterUsers;
- (void)setupUI;
- (void)setupTitle;
- (void)loadAllData;
- (void)loadData:(NSInteger)index;
- (void)searchTextFieldChange:(SearchTextField *)textfield;
- (void)searchTextFieldChangeWithTextfield:(SearchTextField *)textfield;
- (void)multiSelectButtonAction:(UIButton *)sender;
- (void)sureButtonAction;
- (void)cancelButtonAction;
- (NEBaseMultiSelectedViewController *)getMultiSelectedViewController:(NSArray<MultiSelectModel *> *)selectedArray;
- (void)selectedCollectionViewAction;
- (void)setTabButtonLine:(NSInteger)index;
- (void)setEmptyViewText:(nullable NSString *)text;
- (void)recentButtonAction;
- (void)friendButtonAction;
- (void)teamButtonAction;
- (void)didSelectContact:(MultiSelectModel *)model;
- (void)didUnselectContact:(MultiSelectModel *)model;
- (void)refreshSelectCount;

@end

NS_ASSUME_NONNULL_END
