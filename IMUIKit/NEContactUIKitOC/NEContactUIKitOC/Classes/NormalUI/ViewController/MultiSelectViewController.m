// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MultiSelectViewController.h"
#import "MultiSelectedViewController.h"
#import "SelectCell.h"
#import "SelectedCell.h"
#import "RecentSelectCell.h"
#import "NormalContactUIColor.h"
#import "ContactConst.h"

@implementation MultiSelectViewController

- (instancetype)initWithFilterUsers:(NSSet<NSString *> *)filterUsers {
  self = [super initWithFilterUsers:filterUsers];
  if (self) {
    self.searchTextField.backgroundColor = [UIColor searchTextFeildBackColor];

    self.sureButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.sureButton setTitleColor:[UIColor disableButtonTitleColor] forState:UIControlStateDisabled];

    self.recentTableView.rowHeight = 56;
    [self.recentTableView registerClass:[SelectCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseSelectCell class])];

    self.friendTableView.rowHeight = 56;
    [self.friendTableView registerClass:[SelectCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseSelectCell class])];

    self.teamTableView.rowHeight = 56;
    [self.teamTableView registerClass:[SelectCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseSelectCell class])];

    [self.selectedCollectionView registerClass:[SelectedCell class] forCellWithReuseIdentifier:NSStringFromClass([NEBaseSelectedCell class])];

    [self.recentCollectionView registerClass:[RecentSelectCell class] forCellWithReuseIdentifier:NSStringFromClass([NEBaseSelectedCell class])];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

/// 获取已选视图控制器-协同版
- (NEBaseMultiSelectedViewController *)getMultiSelectedViewController:(NSArray<MultiSelectModel *> *)selectedArray {
  return [[MultiSelectedViewController alloc] initWithSelectedArray:selectedArray];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView == self.currentTableView) {
    id info = self.viewModel.sessions[indexPath.row];
    SelectCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEBaseSelectCell class])
                                                       forIndexPath:indexPath];
    [cell showSelect:self.isMultiSelect];
    [cell setModel:info];
    cell.searchText = self.searchText;
    return cell;
  }

  return [[UITableViewCell alloc] init];
}

@end
