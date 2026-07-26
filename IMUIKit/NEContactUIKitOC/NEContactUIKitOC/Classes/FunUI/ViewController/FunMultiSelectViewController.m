// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunMultiSelectViewController.h"
#import "FunMultiSelectedViewController.h"
#import "FunSelectCell.h"
#import "FunSelectedCell.h"
#import "FunRecentSelectCell.h"
#import "FunContactUIColor.h"
#import "ContactConst.h"
#import <NEChatKit/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation FunMultiSelectViewController

- (instancetype)initWithFilterUsers:(NSSet<NSString *> *)filterUsers {
  self = [super initWithFilterUsers:filterUsers];
  if (self) {
    self.themeColor = [UIColor funContactThemeColor];
    self.titleText = contactLocalizable(@"select");
    self.sureButtonText = commonLocalizable(@"complete");
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.98 alpha:1.0];

  [self.sureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.sureButton.backgroundColor = [UIColor funContactThemeDisableColor];
  self.sureButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;

  self.searchTextField.font = [UIFont systemFontOfSize:16];
  self.searchTextField.backgroundColor = [UIColor whiteColor];
  [self.searchTextField addTarget:self action:@selector(searchTextFieldBeginEdit) forControlEvents:UIControlEventEditingDidBegin];
  [self setSearchTextFieldLeftView];

  self.recentTableView.rowHeight = 64;
  [self.recentTableView registerClass:[FunSelectCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseSelectCell class])];

  self.friendTableView.rowHeight = 64;
  [self.friendTableView registerClass:[FunSelectCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseSelectCell class])];

  self.teamTableView.rowHeight = 64;
  [self.teamTableView registerClass:[FunSelectCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseSelectCell class])];

  [self.selectedCollectionView registerClass:[FunSelectedCell class] forCellWithReuseIdentifier:NSStringFromClass([NEBaseSelectedCell class])];

  // recentLabel.textColor = [UIColor blackColor];
  [self.recentCollectionView registerClass:[FunRecentSelectCell class] forCellWithReuseIdentifier:NSStringFromClass([NEBaseSelectedCell class])];
  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

/// 设置搜索框 leftView
- (void)setSearchTextFieldLeftView {
  if (!self.searchTextField.isFirstResponder && (self.searchTextField.text.length == 0)) {
    UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"fun_search"]];
    self.searchTextField.leftView = leftImageView;
    self.searchTextField.leftViewRectX = @([UIScreen mainScreen].bounds.size.width / 2 - 50);
  } else {
    self.searchTextField.leftView = nil;
    self.searchTextField.leftViewRectX = nil;
  }
  [self.searchTextField layoutIfNeeded];
}

/// 监听搜索框开始编辑
- (void)searchTextFieldBeginEdit {
  [self setSearchTextFieldLeftView];
}

/// 获取已选视图控制器 - 通用版
- (NEBaseMultiSelectedViewController *)getMultiSelectedViewController:(NSArray<MultiSelectModel *> *)selectedArray {
  return [[FunMultiSelectedViewController alloc] initWithSelectedArray:selectedArray];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView == self.currentTableView) {
    id info = self.viewModel.sessions[indexPath.row];
    FunSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEBaseSelectCell class])
                                                          forIndexPath:indexPath];
    [cell showSelect:self.isMultiSelect];
    [cell setModel:info];
    cell.searchText = self.searchText;
    return cell;
  }

  return [[UITableViewCell alloc] init];
}

/// 重写 tableView 点击事件，更新搜索框 leftView 位置
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  [self setSearchTextFieldLeftView];
}

#pragma mark - UIScrollViewDelegate

/// 重写 tableView 开始滚动事件，更新搜索框 leftView 位置
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [super scrollViewWillBeginDragging:scrollView];
  [self setSearchTextFieldLeftView];
}

#pragma mark - Collection View DataSource And Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.recentCollectionView) {
    return CGSizeMake(72, 84);
  } else if (collectionView == self.selectedCollectionView) {
    return CGSizeMake(41, self.selectedContentViewHeight);
  } else {
    return CGSizeZero;
  }
}

/// 重写【完成】按钮设置
- (void)refreshSelectCount {
  [super refreshSelectCount];
  self.sureButton.backgroundColor = self.selectedArray.count == 0 ? [UIColor funContactThemeDisableColor] : [UIColor funContactThemeColor];
}

@end
