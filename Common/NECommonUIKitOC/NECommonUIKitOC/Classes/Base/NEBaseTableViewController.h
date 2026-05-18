// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 带 UITableView 的基础控制器
@interface NEBaseTableViewController : NEBaseViewController

/// grouped 风格的 tableView（懒加载）
@property (nonatomic, strong) UITableView *tableView;

/// 将 tableView 添加到 view 并设置约束（top = topConstant）
- (void)setupTable;

@end

NS_ASSUME_NONNULL_END